# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ProjectService do
  include SearchResultHelpers
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'when a single project provided' do
    it_behaves_like 'EE search service shared examples', ::Gitlab::ProjectSearchResults, ::Gitlab::Elastic::ProjectSearchResults do
      let_it_be(:scope) { create(:project) }

      let(:user) { scope.first_owner }
      let(:service) { described_class.new(scope, user, params) }
    end

    context 'and project is archived' do
      it 'uses basic project search' do
        project        = instance_double(Project, archived?: true)
        user           = instance_double(User)
        search_results = instance_double(Gitlab::ProjectSearchResults)
        params         = { search: "foo" }
        search_service = described_class.new(project, user, params)

        expect(Gitlab::ProjectSearchResults).to receive(:new).with(
          user,
          params[:search],
          project: project,
          repository_ref: params[:repository_ref],
          order_by: params[:order_by],
          sort: params[:sort],
          filters: { confidential: params[:confidential], state: params[:state] }
        ).and_return search_results

        expect(search_service.execute).to eq(search_results)
      end
    end
  end

  context 'when a multiple projects provided' do
    it_behaves_like 'EE search service shared examples', ::Gitlab::ProjectSearchResults, ::Gitlab::Elastic::SearchResults do
      let_it_be(:group) { create(:group) }
      let_it_be(:scope) { create_list(:project, 3, namespace: group) }

      let(:user) { group.owner }
      let(:service) { described_class.new(scope, user, params) }
    end
  end

  context 'default branch support' do
    let_it_be(:scope) { create(:project) }

    let(:user) { scope.owner }
    let(:service) { described_class.new(scope, user, params) }

    describe '#use_default_branch?' do
      subject { service.use_default_branch? }

      context 'when repository_ref param is blank' do
        let(:params) { { search: '*' } }

        it { is_expected.to be_truthy }
      end

      context 'when repository_ref param provided' do
        let(:params) { { search: '*', scope: search_scope, repository_ref: 'test' } }

        where(:search_scope, :default_branch_given, :use_default_branch) do
          'issues'          | true   | true
          'issues'          | false  | true
          'merge_requests'  | true   | true
          'merge_requests'  | false  | true
          'notes'           | true   | true
          'notes'           | false  | true
          'milestones'      | true   | true
          'milestones'      | false  | true
          'blobs'           | true   | true
          'blobs'           | false  | false
          'wiki_blobs'      | true   | true
          'wiki_blobs'      | false  | false
          'commits'         | true   | true
          'commits'         | false  | false
        end

        with_them do
          before do
            allow(scope).to receive(:root_ref?).and_return(default_branch_given)
          end

          it { is_expected.to eq(use_default_branch) }
        end
      end
    end

    describe '#execute' do
      let(:params) { { search: '*' } }

      subject { service.execute }

      it 'returns Elastic results when searching non-default branch' do
        expect(service).to receive(:use_default_branch?).and_return(true)

        is_expected.to be_a(::Gitlab::Elastic::ProjectSearchResults)
      end

      it 'returns ordinary results when searching non-default branch' do
        expect(service).to receive(:use_default_branch?).and_return(false)

        is_expected.to be_a(::Gitlab::ProjectSearchResults)
      end
    end
  end

  context 'visibility', :elastic_delete_by_query, :clean_gitlab_redis_shared_state, :sidekiq_inline do
    include_context 'ProjectPolicyTable context'

    shared_examples 'search respects visibility' do
      it 'respects visibility' do
        enable_admin_mode!(user) if admin_mode
        projects.each do |project|
          update_feature_access_level(project, feature_access_level, visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s))
        end

        ensure_elasticsearch_index!

        expect_search_results(user, scope, expected_count: expected_count) do |user|
          described_class.new(project, user, search: search).execute
        end
      end
    end

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, namespace: group) }
    let_it_be_with_reload(:project2) { create(:project) }

    let(:user) { create_user_from_membership(project, membership) }
    let(:projects) { [project, project2] }

    context 'merge request' do
      let!(:merge_request) { create :merge_request, target_project: project, source_project: project }
      let!(:merge_request2) { create :merge_request, target_project: project2, source_project: project2, title: merge_request.title }
      let(:scope) { 'merge_requests' }
      let(:search) { merge_request.title }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it_behaves_like 'search respects visibility'
      end
    end

    context 'blob and commit' do
      let_it_be_with_reload(:project) { create(:project, :repository, namespace: group ) }
      let_it_be_with_reload(:project2) { create(:project, :repository) }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access_and_non_private_project_only
      end

      with_them do
        before do
          project.repository.index_commits_and_blobs
          project2.repository.index_commits_and_blobs
        end

        context 'populate_commit_permissions_in_main_index migration has not been completed' do
          before do
            set_elasticsearch_migration_to(:populate_commit_permissions_in_main_index, including: false)
          end

          it_behaves_like 'search respects visibility' do
            let(:scope) { 'commits' }
            let(:search) { 'initial' }
          end
        end

        it_behaves_like 'search respects visibility' do
          let(:scope) { 'commits' }
          let(:search) { 'initial' }
        end

        it_behaves_like 'search respects visibility' do
          let(:scope) { 'blobs' }
          let(:search) { '.gitmodules' }
        end
      end
    end

    context 'note' do
      let(:scope) { 'notes' }
      let(:search) { note.note }

      context 'on issues' do
        let!(:note) { create :note_on_issue, project: project }
        let!(:note2) { create :note_on_issue, project: project2, note: note.note }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_guest_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end

      context 'on merge requests' do
        let!(:note) { create :note_on_merge_request, project: project }
        let!(:note2) { create :note_on_merge_request, project: project2, note: note.note }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_reporter_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end

      context 'on commits' do
        let_it_be_with_reload(:project) { create(:project, :repository, namespace: group ) }
        let_it_be_with_reload(:project2) { create(:project, :repository) }

        let!(:note) { create :note_on_commit, project: project }
        let!(:note2) { create :note_on_commit, project: project2, note: note.note }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_guest_feature_access_and_non_private_project_only
        end

        with_them do
          before do
            project.repository.index_commits_and_blobs
            project2.repository.index_commits_and_blobs
          end

          it_behaves_like 'search respects visibility'
        end
      end

      context 'on snippets' do
        let!(:note) { create :note_on_project_snippet, project: project }
        let!(:note2) { create :note_on_project_snippet, project: project2, note: note.note }

        where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
          permission_table_for_guest_feature_access
        end

        with_them do
          it_behaves_like 'search respects visibility'
        end
      end
    end

    context 'issue' do
      let!(:issue) { create :issue, project: project }
      let!(:issue2) { create :issue, project: project2, title: issue.title }
      let(:scope) { 'issues' }
      let(:search) { issue.title }

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'search respects visibility'
      end
    end

    context 'wiki' do
      let_it_be_with_reload(:project) { create(:project, :wiki_repo) }

      let(:projects) { [project] }
      let(:scope) { 'wiki_blobs' }
      let(:search) { 'term' }

      before do
        project.wiki.create_page('test.md', "# term")
        project.wiki.index_wiki_blobs
      end

      where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it_behaves_like 'search respects visibility'
      end
    end

    context 'milestone' do
      let!(:milestone) { create :milestone, project: project }

      where(:project_level, :issues_access_level, :merge_requests_access_level, :membership, :admin_mode, :expected_count) do
        permission_table_for_milestone_access
      end

      with_them do
        it "respects visibility" do
          enable_admin_mode!(user) if admin_mode
          project.update!(
            visibility_level: Gitlab::VisibilityLevel.level_value(project_level.to_s),
            issues_access_level: issues_access_level,
            merge_requests_access_level: merge_requests_access_level
          )

          ensure_elasticsearch_index!

          expect_search_results(user, 'milestones', expected_count: expected_count) do |user|
            described_class.new(project, user, search: milestone.title).execute
          end
        end
      end
    end
  end

  context 'sorting', :elastic, :clean_gitlab_redis_shared_state, :sidekiq_inline do
    context 'issues' do
      let(:scope) { 'issues' }
      let_it_be(:project) { create(:project, :public) }

      let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(project, nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(project, nil, search: 'updated', sort: sort).execute }
      end
    end

    context 'merge requests' do
      let(:scope) { 'merge_requests' }
      let(:project) { create(:project, :public) }

      let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(project, nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(project, nil, search: 'updated', sort: sort).execute }
      end
    end
  end
end
