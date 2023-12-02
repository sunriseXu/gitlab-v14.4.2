# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Users" do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)
  end

  describe 'Tabs' do
    let(:tabs_selector) { '.js-users-tabs' }
    let(:active_tab_selector) { '.nav-link.active' }

    it 'links to the Users tab' do
      visit admin_cohorts_path

      within tabs_selector do
        click_link 'Users'

        expect(page).to have_selector active_tab_selector, text: 'Users'
      end

      expect(page).to have_current_path(admin_users_path)
    end

    it 'links to the Cohorts tab' do
      visit admin_users_path

      within tabs_selector do
        click_link 'Cohorts'

        expect(page).to have_selector active_tab_selector, text: 'Cohorts'
      end

      expect(page).to have_current_path(admin_cohorts_path)
      expect(page).to have_selector active_tab_selector, text: 'Cohorts'
    end

    it 'redirects legacy route' do
      visit admin_users_path(tab: 'cohorts')

      expect(page).to have_current_path(admin_cohorts_path)
    end
  end

  describe 'Cohorts tab content' do
    it 'shows users count per month' do
      stub_application_setting(usage_ping_enabled: false)

      create_list(:user, 2)

      visit admin_users_path(tab: 'cohorts')

      expect(page).to have_content("#{Time.zone.now.strftime('%b %Y')} 3 0")
    end
  end

  describe 'prompt user about registration features' do
    let(:message) { s_("RegistrationFeatures|Want to %{feature_title} for free?") % { feature_title: s_('RegistrationFeatures|send emails to users') } }

    it 'does not render registration features CTA when service ping is enabled' do
      stub_application_setting(usage_ping_enabled: true)

      visit admin_users_path

      expect(page).not_to have_content(message)
    end

    context 'with no license and service ping disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)

        if Gitlab.ee?
          allow(License).to receive(:current).and_return(nil)
        end
      end

      it 'renders registration features CTA' do
        visit admin_users_path

        expect(page).to have_content(message)
        expect(page).to have_link(s_('RegistrationFeatures|Registration Features Program'))
      end
    end
  end
end
