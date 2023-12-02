# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedBranches do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:protected_name) { 'feature' }
  let(:branch_name) { protected_name }

  let!(:protected_branch) do
    create(:protected_branch, project: project, name: protected_name)
  end

  before_all do
    project.add_maintainer(maintainer)
    project.add_guest(guest)
  end

  describe "GET /projects/:id/protected_branches" do
    let(:params) { {} }
    let(:route) { "/projects/#{project.id}/protected_branches" }

    shared_examples_for 'protected branches' do
      it 'returns the protected branches' do
        get api(route, user), params: params.merge(per_page: 100)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        protected_branch_names = json_response.map { |x| x['name'] }
        expect(protected_branch_names).to match_array(expected_branch_names)
      end
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      context 'when search param is not present' do
        it_behaves_like 'protected branches' do
          let(:expected_branch_names) { project.protected_branches.map { |x| x['name'] } }
        end
      end

      context 'when search param is present' do
        it_behaves_like 'protected branches' do
          let(:another_protected_branch) { create(:protected_branch, project: project, name: 'stable') }
          let(:params) { { search: another_protected_branch.name } }
          let(:expected_branch_names) { [another_protected_branch.name] }
        end
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe "GET /projects/:id/protected_branches/:branch" do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    shared_examples_for 'protected branch' do
      it 'returns the protected branch' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
      end

      context 'when protected branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, user) }
          let(:message) { '404 Not found' }
        end
      end
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      it_behaves_like 'protected branch'

      context 'when protected branch contains a wildcard' do
        let(:protected_name) { 'feature*' }

        it_behaves_like 'protected branch'
      end

      context 'when protected branch contains a period' do
        let(:protected_name) { 'my.feature' }

        it_behaves_like 'protected branch'
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe 'POST /projects/:id/protected_branches' do
    let(:branch_name) { 'new_branch' }
    let(:post_endpoint) { api("/projects/#{project.id}/protected_branches", user) }

    def expect_protection_to_be_successful
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(branch_name)
    end

    context 'when authenticated as a maintainer' do
      let(:user) { maintainer }

      it 'protects a single branch' do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and developers can push' do
        post post_endpoint, params: { name: branch_name, push_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and developers can merge' do
        post post_endpoint, params: { name: branch_name, merge_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and developers can push and merge' do
        post post_endpoint, params: { name: branch_name, push_access_level: 30, merge_access_level: 30 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'protects a single branch and no one can push' do
        post post_endpoint, params: { name: branch_name, push_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and no one can merge' do
        post post_endpoint, params: { name: branch_name, merge_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'protects a single branch and no one can push or merge' do
        post post_endpoint, params: { name: branch_name, push_access_level: 0, merge_access_level: 0 }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(false)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'protects a single branch and allows force pushes' do
        post post_endpoint, params: { name: branch_name, allow_force_push: true }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['allow_force_push']).to eq(true)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'returns a 409 error if the same branch is protected twice' do
        post post_endpoint, params: { name: protected_name }

        expect(response).to have_gitlab_http_status(:conflict)
      end

      context 'when branch has a wildcard in its name' do
        let(:branch_name) { 'feature/*' }

        it "protects multiple branches with a wildcard in the name" do
          post post_endpoint, params: { name: branch_name }

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
          expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when a policy restricts rule creation' do
        it "prevents creations of the protected branch rule" do
          disallow(:create_protected_branch, an_instance_of(ProtectedBranch))

          post post_endpoint, params: { name: branch_name }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authenticated as a guest' do
      let(:user) { guest }

      it "returns a 403 error if guest" do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /projects/:id/protected_branches/unprotect/:branch" do
    let(:user) { maintainer }
    let(:delete_endpoint) { api("/projects/#{project.id}/protected_branches/#{branch_name}", user) }

    it "unprotects a single branch" do
      delete delete_endpoint

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it_behaves_like '412 response' do
      let(:request) { delete_endpoint }
    end

    it "returns 404 if branch does not exist" do
      delete api("/projects/#{project.id}/protected_branches/barfoo", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when a policy restricts rule deletion' do
      it "prevents deletion of the protected branch rule" do
        disallow(:destroy_protected_branch, protected_branch)

        delete delete_endpoint

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when branch has a wildcard in its name' do
      let(:protected_name) { 'feature*' }

      it "unprotects a wildcard branch" do
        delete delete_endpoint

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
