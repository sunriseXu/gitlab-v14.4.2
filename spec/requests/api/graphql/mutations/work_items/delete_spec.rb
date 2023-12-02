# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a work item' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }

  let(:current_user) { developer }
  let(:mutation) { graphql_mutation(:workItemDelete, { 'id' => work_item.to_global_id.to_s }) }
  let(:mutation_response) { graphql_mutation_response(:work_item_delete) }

  context 'when the user is not allowed to delete a work item' do
    let(:work_item) { create(:work_item, project: project) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to delete a work item' do
    let_it_be(:authored_work_item, refind: true) { create(:work_item, project: project, author: developer, assignees: [developer]) }

    let(:work_item) { authored_work_item }

    it 'deletes the work item' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change(WorkItem, :count).by(-1)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['project']).to include('id' => work_item.project.to_global_id.to_s)
    end

    context 'when the work_items feature flag is disabled' do
      before do
        stub_feature_flags(work_items: false)
      end

      it 'does not delete the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to not_change(WorkItem, :count)

        expect(mutation_response['errors']).to contain_exactly('`work_items` feature flag disabled for this project')
      end
    end
  end
end
