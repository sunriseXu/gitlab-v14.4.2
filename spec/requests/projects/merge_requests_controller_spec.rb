# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController do
  describe 'GET #discussions' do
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:project) { merge_request.project }
    let_it_be(:user) { merge_request.author }
    let_it_be(:discussion) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let_it_be(:discussion_reply) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project, in_reply_to: discussion) }
    let_it_be(:state_event) { create(:resource_state_event, merge_request: merge_request) }
    let_it_be(:discussion_2) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let_it_be(:discussion_3) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

    before do
      login_as(user)
    end

    context 'pagination' do
      def get_discussions(**params)
        get discussions_project_merge_request_path(project, merge_request, params: params.merge(format: :json))
      end

      it 'returns paginated notes and cursor based on per_page param' do
        get_discussions(per_page: 2)

        discussions = Gitlab::Json.parse(response.body)
        notes = discussions.flat_map { |d| d['notes'] }

        expect(discussions.count).to eq(2)
        expect(notes).to match([
          a_hash_including('id' => discussion.id.to_s),
          a_hash_including('id' => discussion_reply.id.to_s),
          a_hash_including('type' => 'StateNote')
        ])

        cursor = response.header['X-Next-Page-Cursor']
        expect(cursor).to be_present

        get_discussions(per_page: 1, cursor: cursor)

        discussions = Gitlab::Json.parse(response.body)
        notes = discussions.flat_map { |d| d['notes'] }

        expect(discussions.count).to eq(1)
        expect(notes).to match([
          a_hash_including('id' => discussion_2.id.to_s)
        ])
      end

      context 'when paginated_mr_discussions is disabled' do
        before do
          stub_feature_flags(paginated_mr_discussions: false)
        end

        it 'returns all discussions and ignores per_page param' do
          get_discussions(per_page: 2)

          discussions = Gitlab::Json.parse(response.body)
          notes = discussions.flat_map { |d| d['notes'] }

          expect(discussions.count).to eq(4)
          expect(notes.count).to eq(5)
        end
      end
    end
  end

  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: true do
        let(:url) { project_merge_requests_url(public_project, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_merge_requests_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end
end
