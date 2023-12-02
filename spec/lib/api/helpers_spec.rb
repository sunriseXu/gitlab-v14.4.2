# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers do
  using RSpec::Parameterized::TableSyntax

  subject(:helper) { Class.new.include(described_class).new }

  describe '#current_user' do
    include Rack::Test::Methods

    let(:user) { build(:user, id: 42) }

    let(:helper) do
      Class.new(Grape::API::Instance) do
        helpers API::APIGuard::HelperMethods
        helpers API::Helpers
        format :json

        get 'user' do
          current_user ? { id: current_user.id } : { found: false }
        end

        get 'protected' do
          authenticate_by_gitlab_geo_node_token!
        end
      end
    end

    def app
      helper
    end

    it 'handles sticking when a user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      expect(ApplicationRecord.sticking)
        .to receive(:stick_or_unstick_request).with(any_args, :user, 42)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })
    end

    it 'does not handle sticking if no user could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(nil)

      expect(ApplicationRecord.sticking)
        .not_to receive(:stick_or_unstick_request)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'found' => false })
    end

    it 'returns the user if one could be found' do
      allow_any_instance_of(API::Helpers).to receive(:initial_current_user).and_return(user)

      get 'user'

      expect(Gitlab::Json.parse(last_response.body)).to eq({ 'id' => user.id })
    end
  end

  describe '#find_project' do
    let(:project) { create(:project) }

    shared_examples 'project finder' do
      context 'when project exists' do
        it 'returns requested project' do
          expect(helper.find_project(existing_id)).to eq(project)
        end

        it 'returns nil' do
          expect(helper.find_project(non_existing_id)).to be_nil
        end
      end

      context 'when project id is not provided' do
        it 'returns nil' do
          expect(helper.find_project(nil)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { project.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'project finder'
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { project.full_path }
      let(:non_existing_id) { 'something/else' }

      it_behaves_like 'project finder'

      context 'with an invalid PATH' do
        let(:non_existing_id) { 'undefined' } # path without slash

        it_behaves_like 'project finder'

        it 'does not hit the database' do
          expect(Project).not_to receive(:find_by_full_path)

          helper.find_project(non_existing_id)
        end
      end
    end

    context 'when project is pending delete' do
      let(:project_pending_delete) { create(:project, pending_delete: true) }

      it 'does not return the project pending delete' do
        expect(Project).not_to receive(:find_by_full_path)

        expect(helper.find_project(project_pending_delete.id)).to be_nil
      end
    end

    context 'when project is hidden' do
      let(:hidden_project) { create(:project, :hidden) }

      it 'does not return the hidden project' do
        expect(Project).not_to receive(:find_by_full_path)

        expect(helper.find_project(hidden_project.id)).to be_nil
      end
    end
  end

  describe '#find_project!' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private project without access' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_project!(project.id)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(helper.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public project' do
        it 'returns requested project' do
          expect(helper.find_project!(project.id)).to eq(project)
        end
      end

      context 'private project' do
        it_behaves_like 'private project without access'
      end
    end

    context 'support for IDs and paths as argument' do
      let_it_be(:project) { create(:project) }

      let(:user) { project.first_owner }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:authorized_project_scope?).and_return(true)
        allow(helper).to receive(:job_token_authentication?).and_return(false)
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      shared_examples 'project finder' do
        context 'when project exists' do
          it 'returns requested project' do
            expect(helper.find_project!(existing_id)).to eq(project)
          end

          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Project Not Found', 404)
            expect(helper.find_project!(non_existing_id)).to be_nil
          end
        end
      end

      context 'when ID is used as an argument' do
        let(:existing_id) { project.id }
        let(:non_existing_id) { non_existing_record_id }

        it_behaves_like 'project finder'
      end

      context 'when PATH is used as an argument' do
        let(:existing_id) { project.full_path }
        let(:non_existing_id) { 'something/else' }

        it_behaves_like 'project finder'

        context 'with an invalid PATH' do
          let(:non_existing_id) { 'undefined' } # path without slash

          it_behaves_like 'project finder'

          it 'does not hit the database' do
            expect(Project).not_to receive(:find_by_full_path)
            expect(helper).to receive(:render_api_error!).with('404 Project Not Found', 404)

            helper.find_project!(non_existing_id)
          end
        end
      end
    end
  end

  describe '#find_group!' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private group without access' do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_group!(group.id)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group!(group.id)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group!(group.id)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end

    context 'support for IDs and paths as arguments' do
      let_it_be(:group) { create(:group) }

      let(:user) { group.first_owner }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:authorized_project_scope?).and_return(true)
        allow(helper).to receive(:job_token_authentication?).and_return(false)
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      shared_examples 'group finder' do
        context 'when group exists' do
          it 'returns requested group' do
            expect(helper.find_group!(existing_id)).to eq(group)
          end

          it 'returns nil' do
            expect(helper).to receive(:render_api_error!).with('404 Group Not Found', 404)
            expect(helper.find_group!(non_existing_id)).to be_nil
          end
        end
      end

      context 'when ID is used as an argument' do
        let(:existing_id) { group.id }
        let(:non_existing_id) { non_existing_record_id }

        it_behaves_like 'group finder'
      end

      context 'when PATH is used as an argument' do
        let(:existing_id) { group.full_path }
        let(:non_existing_id) { 'something/else' }

        it_behaves_like 'group finder'
      end
    end
  end

  describe '#find_group_by_full_path!' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    shared_examples 'private group without access' do
      before do
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        allow(helper).to receive(:authenticate_non_public?).and_return(false)
      end

      it 'returns not found' do
        expect(helper).to receive(:not_found!)

        helper.find_group_by_full_path!(group.full_path)
      end
    end

    context 'when user is authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:initial_current_user).and_return(user)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'

        context 'with access' do
          before do
            group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
            group.add_developer(user)
          end

          it 'returns requested group with access' do
            expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
          end
        end
      end
    end

    context 'when user is not authenticated' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:initial_current_user).and_return(nil)
      end

      context 'public group' do
        it 'returns requested group' do
          expect(helper.find_group_by_full_path!(group.full_path)).to eq(group)
        end
      end

      context 'private group' do
        it_behaves_like 'private group without access'
      end
    end
  end

  describe '#find_namespace' do
    let(:namespace) { create(:namespace) }

    shared_examples 'namespace finder' do
      context 'when namespace exists' do
        it 'returns requested namespace' do
          expect(helper.find_namespace(existing_id)).to eq(namespace)
        end
      end

      context "when namespace doesn't exists" do
        it 'returns nil' do
          expect(helper.find_namespace(non_existing_id)).to be_nil
        end
      end
    end

    context 'when ID is used as an argument' do
      let(:existing_id) { namespace.id }
      let(:non_existing_id) { non_existing_record_id }

      it_behaves_like 'namespace finder'
    end

    context 'when PATH is used as an argument' do
      let(:existing_id) { namespace.path }
      let(:non_existing_id) { 'non-existing-path' }

      it_behaves_like 'namespace finder'
    end
  end

  shared_examples 'user namespace finder' do
    let(:user1) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user1)
      allow(helper).to receive(:header).and_return(nil)
      allow(helper).to receive(:not_found!).and_raise('404 Namespace not found')
    end

    context 'when namespace is group' do
      let(:namespace) { create(:group) }

      context 'when user has access to group' do
        before do
          namespace.add_guest(user1)
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't have access to group" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end

    context "when namespace is user's personal namespace" do
      let(:namespace) { create(:namespace) }

      context 'when user owns the namespace' do
        before do
          namespace.owner = user1
          namespace.save!
        end

        it 'returns requested namespace' do
          expect(namespace_finder).to eq(namespace)
        end
      end

      context "when user doesn't own the namespace" do
        it 'raises not found error' do
          expect { namespace_finder }.to raise_error(RuntimeError, '404 Namespace not found')
        end
      end
    end
  end

  describe '#find_namespace!' do
    let(:namespace_finder) do
      helper.find_namespace!(namespace.id)
    end

    it_behaves_like 'user namespace finder'
  end

  describe '#authorized_project_scope?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:job) { create(:ci_build) }

    let(:send_authorized_project_scope) { helper.authorized_project_scope?(project) }

    where(:job_token_authentication, :route_setting, :feature_flag, :same_job_project, :expected_result) do
      false | false | false | false | true
      false | false | false | true  | true
      false | false | true  | false | true
      false | false | true  | true  | true
      false | true  | false | false | true
      false | true  | false | true  | true
      false | true  | true  | false | true
      false | true  | true  | true  | true
      true  | false | false | false | true
      true  | false | false | true  | true
      true  | false | true  | false | true
      true  | false | true  | true  | true
      true  | true  | false | false | false
      true  | true  | false | true  | false
      true  | true  | true  | false | false
      true  | true  | true  | true  | true
    end

    with_them do
      before do
        allow(helper).to receive(:job_token_authentication?).and_return(job_token_authentication)
        allow(helper).to receive(:route_authentication_setting).and_return(job_token_scope: route_setting ? :project : nil)
        allow(helper).to receive(:current_authenticated_job).and_return(job)
        allow(job).to receive(:project).and_return(same_job_project ? project : other_project)

        stub_feature_flags(ci_job_token_scope: false)
        stub_feature_flags(ci_job_token_scope: project) if feature_flag
      end

      it 'returns the expected result' do
        expect(send_authorized_project_scope).to eq(expected_result)
      end
    end
  end

  describe '#send_git_blob' do
    let(:repository) { double }
    let(:blob) { double(name: 'foobar') }

    let(:send_git_blob) do
      helper.send(:send_git_blob, repository, blob)
      helper.header
    end

    before do
      allow(helper).to receive(:env).and_return({})
      allow(helper).to receive(:content_type)
      allow(helper).to receive(:header).and_return({})
      allow(helper).to receive(:body).and_return('')
      allow(Gitlab::Workhorse).to receive(:send_git_blob)
    end

    it 'sets Gitlab::Workhorse::DETECT_HEADER header' do
      expect(send_git_blob[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
    end

    context 'content disposition' do
      context 'when blob name is null' do
        let(:blob) { double(name: nil) }

        it 'returns only the disposition' do
          expect(send_git_blob['Content-Disposition']).to eq 'inline'
        end
      end

      context 'when blob name is not null' do
        it 'returns disposition with the blob name' do
          expect(send_git_blob['Content-Disposition']).to eq %q(inline; filename="foobar"; filename*=UTF-8''foobar)
        end
      end
    end
  end

  describe '#increment_unique_values' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    it 'tracks redis hll event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: value)

      helper.increment_unique_values(event_name, value)
    end

    it 'logs an exception for unknown event' do
      expect(Gitlab::AppLogger).to receive(:warn).with("Redis tracking event failed for event: #{unknown_event}, message: Unknown event #{unknown_event}")

      helper.increment_unique_values(unknown_event, value)
    end

    it 'does not track event for nil values' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.increment_unique_values(unknown_event, nil)
    end
  end

  shared_examples '#order_options_with_tie_breaker' do
    subject { Class.new.include(described_class).new.order_options_with_tie_breaker }

    before do
      allow_any_instance_of(described_class).to receive(:params).and_return(params)
    end

    context 'with non-id order given' do
      context 'with ascending order' do
        let(:params) { { order_by: 'name', sort: 'asc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'asc', 'id' => 'asc' })
        end
      end

      context 'with descending order' do
        let(:params) { { order_by: 'name', sort: 'desc' } }

        it 'adds id based ordering with same direction as primary order' do
          is_expected.to eq({ 'name' => 'desc', 'id' => 'desc' })
        end
      end
    end

    context 'with non-id order but no direction given' do
      let(:params) { { order_by: 'name' } }

      it 'adds ID ASC order' do
        is_expected.to eq({ 'name' => nil, 'id' => 'asc' })
      end
    end

    context 'with id order given' do
      let(:params) { { order_by: 'id', sort: 'asc' } }

      it 'does not add an additional order' do
        is_expected.to eq({ 'id' => 'asc' })
      end
    end
  end

  describe '#order_options_with_tie_breaker' do
    include_examples '#order_options_with_tie_breaker'

    context 'with created_at order given' do
      let(:params) { { order_by: 'created_at', sort: 'asc' } }

      it 'converts to id' do
        is_expected.to eq({ 'id' => 'asc' })
      end
    end
  end

  describe "#destroy_conditionally!" do
    let!(:project) { create(:project) }

    context 'when unmodified check passes' do
      before do
        allow(helper).to receive(:check_unmodified_since!).with(project.updated_at).and_return(true)
      end

      it 'destroys given project' do
        allow(helper).to receive(:status).with(204)
        allow(helper).to receive(:body).with(false)
        expect(project).to receive(:destroy).and_call_original

        expect { helper.destroy_conditionally!(project) }.to change(Project, :count).by(-1)
      end
    end

    context 'when unmodified check fails' do
      before do
        allow(helper).to receive(:check_unmodified_since!).with(project.updated_at).and_throw(:error)
      end

      # #destroy_conditionally! uses Grape errors which Ruby-throws a symbol, shifting execution to somewhere else.
      # Since this spec isn't in the Grape context, we need to simulate this ourselves.
      # Grape throws here: https://github.com/ruby-grape/grape/blob/470f80cd48933cdf11d4c1ee02cb43e0f51a7300/lib/grape/dsl/inside_route.rb#L168-L171
      # And catches here: https://github.com/ruby-grape/grape/blob/cf57d250c3d77a9a488d9f56918d62fd4ac745ff/lib/grape/middleware/error.rb#L38-L40
      it 'does not destroy given project' do
        expect(project).not_to receive(:destroy)

        expect { helper.destroy_conditionally!(project) }.to throw_symbol(:error).and change { Project.count }.by(0)
      end
    end
  end

  describe "#check_unmodified_since!" do
    let(:unmodified_since_header) { Time.now.change(usec: 0) }

    before do
      allow(helper).to receive(:headers).and_return('If-Unmodified-Since' => unmodified_since_header.to_s)
    end

    context 'when last modified is later than header value' do
      it 'renders error' do
        expect(helper).to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header + 1.hour)
      end
    end

    context 'when last modified is earlier than header value' do
      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header - 1.hour)
      end
    end

    context 'when last modified is equal to header value' do
      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(unmodified_since_header)
      end
    end

    context 'when there is no header value present' do
      let(:unmodified_since_header) { nil }

      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(Time.now)
      end
    end

    context 'when header value is not a valid time value' do
      let(:unmodified_since_header) { "abcd" }

      it 'does not render error' do
        expect(helper).not_to receive(:render_api_error!)

        helper.check_unmodified_since!(Time.now)
      end
    end
  end

  describe '#present_disk_file!' do
    let_it_be(:dummy_class) do
      Class.new do
        attr_reader :headers
        alias_method :header, :headers

        def initialize
          @headers = {}
        end
      end
    end

    let(:dummy_instance) { dummy_class.include(described_class).new }
    let(:path) { '/tmp/file.txt' }
    let(:filename) { 'file.txt' }

    subject { dummy_instance.present_disk_file!(path, filename) }

    before do
      expect(dummy_instance).to receive(:content_type).with('application/octet-stream')
    end

    context 'with X-Sendfile supported' do
      before do
        dummy_instance.headers['X-Sendfile-Type'] = 'X-Sendfile'
      end

      it 'sends the file using X-Sendfile' do
        expect(dummy_instance).to receive(:body).with('')

        subject

        expect(dummy_instance.headers['X-Sendfile']).to eq(path)
      end
    end

    context 'without X-Sendfile supported' do
      it 'sends the file' do
        expect(dummy_instance).to receive(:sendfile).with(path)

        subject
      end
    end
  end

  describe '#order_by_similarity?' do
    where(:params, :allow_unauthorized, :current_user_set, :expected) do
      {}                                          | false | false | false
      {}                                          | true  | false | false
      {}                                          | false | true  | false
      {}                                          | true  | true  | false
      { order_by: 'similarity' }                  | false | false | false
      { order_by: 'similarity' }                  | true  | false | false
      { order_by: 'similarity' }                  | true  | true  | false
      { order_by: 'similarity' }                  | false | true  | false
      { search: 'test' }                          | false | false | false
      { search: 'test' }                          | true  | false | false
      { search: 'test' }                          | true  | true  | false
      { search: 'test' }                          | false | true  | false
      { order_by: 'similarity', search: 'test' }  | false | false | false
      { order_by: 'similarity', search: 'test' }  | true  | false | true
      { order_by: 'similarity', search: 'test' }  | true  | true  | true
      { order_by: 'similarity', search: 'test' }  | false | true  | true
    end

    with_them do
      let_it_be(:user) { create(:user) }

      before do
        u = current_user_set ? user : nil
        helper.instance_variable_set(:@current_user, u)

        allow(helper).to receive(:params).and_return(params)
      end

      it 'returns the expected result' do
        expect(helper.order_by_similarity?(allow_unauthorized: allow_unauthorized)).to eq(expected)
      end
    end
  end

  describe '#render_api_error_with_reason!' do
    before do
      allow(helper).to receive(:env).and_return({})
      allow(helper).to receive(:header).and_return({})
      allow(helper).to receive(:error!)
    end

    it 'renders error with code' do
      expect(helper).to receive(:set_status_code_in_env).with(999)
      expect(helper).to receive(:error!).with({ 'message' => 'a message - good reason' }, 999, {})

      helper.render_api_error_with_reason!(999, 'a message', 'good reason')
    end
  end

  describe '#unauthorized!' do
    it 'renders 401' do
      expect(helper).to receive(:render_api_error_with_reason!).with(401, '401 Unauthorized', nil)

      helper.unauthorized!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(401, '401 Unauthorized', 'custom reason')

      helper.unauthorized!('custom reason')
    end
  end

  describe '#forbidden!' do
    it 'renders 401' do
      expect(helper).to receive(:render_api_error_with_reason!).with(403, '403 Forbidden', nil)

      helper.forbidden!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(403, '403 Forbidden', 'custom reason')

      helper.forbidden!('custom reason')
    end
  end

  describe '#bad_request!' do
    it 'renders 400' do
      expect(helper).to receive(:render_api_error_with_reason!).with(400, '400 Bad request', nil)

      helper.bad_request!
    end

    it 'renders 401 with a reason' do
      expect(helper).to receive(:render_api_error_with_reason!).with(400, '400 Bad request', 'custom reason')

      helper.bad_request!('custom reason')
    end
  end

  describe '#authenticate_by_gitlab_shell_token!' do
    include GitlabShellHelpers

    let(:valid_secret_token) { 'valid' }
    let(:invalid_secret_token) { 'invalid' }
    let(:headers) { {} }
    let(:params) { {} }

    shared_examples 'authorized' do
      it 'authorized' do
        expect(helper).not_to receive(:unauthorized!)

        helper.authenticate_by_gitlab_shell_token!
      end
    end

    shared_examples 'unauthorized' do
      it 'unauthorized' do
        expect(helper).to receive(:unauthorized!)

        helper.authenticate_by_gitlab_shell_token!
      end
    end

    before do
      allow(Gitlab::Shell).to receive(:secret_token).and_return(valid_secret_token)
      allow(helper).to receive_messages(params: params, headers: headers, secret_token: valid_secret_token)
    end

    context 'when jwt token is not provided' do
      it_behaves_like 'unauthorized'
    end

    context 'when jwt token is invalid' do
      let(:headers) { gitlab_shell_internal_api_request_header(secret_token: invalid_secret_token) }

      it_behaves_like 'unauthorized'
    end

    context 'when jwt token issuer is invalid' do
      let(:headers) { gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse') }

      it_behaves_like 'unauthorized'
    end

    context 'when jwt token is valid' do
      let(:headers) { gitlab_shell_internal_api_request_header }

      it_behaves_like 'authorized'
    end

    context 'when gitlab_shell_jwt_token is disabled' do
      let(:valid_secret_token) { +'valid' } # mutable string to use chomp!
      let(:invalid_secret_token) { +'invalid' } # mutable string to use chomp!

      before do
        stub_feature_flags(gitlab_shell_jwt_token: false)
      end

      context 'when shared secret is not provided' do
        it_behaves_like 'unauthorized'
      end

      context 'when shared secret provided via params' do
        let(:params) { { 'secret_token' => valid_secret_token } }

        it_behaves_like 'authorized'

        context 'but it is invalid' do
          let(:params) { { 'secret_token' => invalid_secret_token } }

          it_behaves_like 'unauthorized'
        end
      end

      context 'when shared secret provided via headers' do
        let(:headers) { { described_class::GITLAB_SHARED_SECRET_HEADER => Base64.encode64(valid_secret_token) } }

        it_behaves_like 'authorized'

        context 'but it is invalid' do
          let(:headers) { { described_class::GITLAB_SHARED_SECRET_HEADER => Base64.encode64(invalid_secret_token) } }

          it_behaves_like 'unauthorized'
        end
      end
    end
  end
end
