# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository > Branch rules settings' do
  let(:project) { create(:project_empty_repo) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  subject(:request) { visit project_settings_repository_branch_rules_path(project) }

  before do
    project.add_role(user, role)
    sign_in(user)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'is not allowed to view' do
      request

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    context 'Branch rules', :js do
      it 'renders branch rules page' do
        request

        expect(page).to have_content('Branch rules')
      end
    end

    context 'branch_rules feature flag disabled' do
      it 'does not render branch rules content' do
        stub_feature_flags(branch_rules: false)
        request

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
