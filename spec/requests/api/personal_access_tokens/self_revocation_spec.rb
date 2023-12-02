# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens::SelfRevocation do
  let_it_be(:current_user) { create(:user) }

  describe 'DELETE /personal_access_tokens/self' do
    let(:path) { '/personal_access_tokens/self' }
    let(:token) { create(:personal_access_token, user: current_user) }

    subject(:delete_token) { delete api(path, personal_access_token: token) }

    shared_examples 'revoking token succeeds' do
      it 'revokes token' do
        delete_token

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token.reload).to be_revoked
      end
    end

    shared_examples 'revoking token denied' do |status|
      it 'cannot revoke token' do
        delete_token

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'when current_user is an administrator', :enable_admin_mode do
      let(:current_user) { create(:admin) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { create(:user) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token denied', :bad_request
      end

      context 'with already revoked token' do
        let(:token) { create(:personal_access_token, :revoked, user: current_user) }

        it_behaves_like 'revoking token denied', :unauthorized
      end
    end

    Gitlab::Auth.all_available_scopes.each do |scope|
      context "with a '#{scope}' scoped token" do
        let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end
  end
end
