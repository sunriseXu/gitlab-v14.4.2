# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group > Settings > Access Tokens', :js do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:bot_user) { create(:user, :project_bot) }
  let_it_be(:group) { create(:group) }
  let_it_be(:resource_settings_access_tokens_path) { group_settings_access_tokens_path(group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  def create_resource_access_token
    group.add_maintainer(bot_user)

    create(:personal_access_token, user: bot_user)
  end

  context 'when user is not a group owner' do
    before do
      group.add_maintainer(user)
    end

    it_behaves_like 'resource access tokens missing access rights'
  end

  describe 'token creation' do
    it_behaves_like 'resource access tokens creation', 'group'

    context 'when token creation is not allowed' do
      it_behaves_like 'resource access tokens creation disallowed', 'Group access token creation is disabled in this group. You can still use and manage existing tokens.'
    end
  end

  describe 'active tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'active resource access tokens'
  end

  describe 'inactive tokens' do
    let!(:resource_access_token) { create_resource_access_token }

    it_behaves_like 'inactive resource access tokens', 'This group has no active access tokens.'
  end
end
