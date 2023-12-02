# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Submodules do
  include NamespaceStorageHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:submodule) { 'six' }

  let(:params) do
    {
      submodule: submodule,
      commit_sha: 'e25eda1fece24ac7a03624ed1320f82396f35bd8',
      branch: 'master',
      commit_message: 'update submodule'
    }
  end

  before do
    project.add_developer(user)
  end

  def route(submodule)
    "/projects/#{project.id}/repository/submodules/#{submodule}"
  end

  describe "PUT /projects/:id/repository/submodule/:submodule" do
    context 'with an exceeded namespace storage limit', :saas do
      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 4)
        set_used_storage(group, megabytes: 5)
      end

      it 'rejects the request' do
        put api(route(submodule), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(
          'Your push to this repository has been rejected because the ' \
          'namespace storage limit of 4 MB has been reached. ' \
          'Reduce your namespace storage or purchase additional storage.'
        )
      end
    end
  end
end
