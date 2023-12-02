# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Files do
  include NamespaceStorageHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, group: group) }
  let(:file_path) { "files%2Fruby%2Fpopen%2Erb" }

  before do
    project.add_developer(user)
  end

  def route(file_path = nil)
    "/projects/#{project.id}/repository/files/#{file_path}"
  end

  describe "POST /projects/:id/repository/files/:file_path" do
    let(:file_path) { "new_subfolder%2Fnewfile%2Erb" }
    let(:params) do
      {
        branch: "master",
        content: "puts 8",
        commit_message: "Added newfile"
      }
    end

    context 'with an exceeded namespace storage limit', :saas do
      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 5)
        set_used_storage(group, megabytes: 6)
      end

      it 'rejects the request' do
        post api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(
          'Your push to this repository has been rejected because the ' \
          'namespace storage limit of 5 MB has been reached. ' \
          'Reduce your namespace storage or purchase additional storage.'
        )
      end
    end
  end

  describe "PUT /projects/:id/repository/files/:file_path" do
    let(:params) do
      {
        branch: 'master',
        content: 'puts 8',
        commit_message: 'Change file'
      }
    end

    context 'with an exceeded namespace storage limit', :saas do
      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 5)
        set_used_storage(group, megabytes: 6)
      end

      it 'rejects the request' do
        put api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(
          'Your push to this repository has been rejected because the ' \
          'namespace storage limit of 5 MB has been reached. ' \
          'Reduce your namespace storage or purchase additional storage.'
        )
      end
    end
  end

  describe "DELETE /projects/:id/repository/files/:file_path" do
    let(:params) do
      {
        branch: 'master',
        commit_message: 'Delete file'
      }
    end

    context 'with an exceeded namespace storage limit', :saas do
      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 5)
        set_used_storage(group, megabytes: 6)
      end

      it 'rejects the request' do
        delete api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(
          'Your push to this repository has been rejected because the ' \
          'namespace storage limit of 5 MB has been reached. ' \
          'Reduce your namespace storage or purchase additional storage.'
        )
      end
    end
  end
end
