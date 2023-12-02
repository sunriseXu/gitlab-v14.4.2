# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAccessTokenEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:bot) { create(:user, :project_bot) }
  let_it_be(:token) { create(:personal_access_token, user: bot) }

  subject(:json) {  described_class.new(token, project: project).as_json }

  context 'when bot is a member of the project' do
    before do
      project.add_developer(bot)
    end

    it 'has the correct attributes' do
      expected_revoke_path = Gitlab::Routing.url_helpers
                                            .revoke_namespace_project_settings_access_token_path(
                                              { id: token,
                                                namespace_id: project.namespace.path,
                                                project_id: project.path })

      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          role: 'Developer'
        ))

      expect(json).not_to include(:token)
    end
  end

  context 'when bot is unrelated to the project' do
    let_it_be(:project) { create(:project) }

    it 'has the correct attributes' do
      expected_revoke_path = Gitlab::Routing.url_helpers
                                            .revoke_namespace_project_settings_access_token_path(
                                              { id: token,
                                                namespace_id: project.namespace.path,
                                                project_id: project.path })

      expect(json).to(
        include(
          id: token.id,
          name: token.name,
          scopes: token.scopes,
          user_id: token.user_id,
          revoke_path: expected_revoke_path,
          role: nil
        ))

      expect(json).not_to include(:token)
    end
  end
end
