# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/general.html.haml' do
  let_it_be(:user) { create(:admin) }
  let_it_be(:app_settings) { build(:application_setting) }

  subject { rendered }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'maintenance mode' do
    let(:maintenance_mode_flag) { true }
    let(:license_allows) { true }

    before do
      stub_feature_flags(maintenance_mode: maintenance_mode_flag)
      allow(Gitlab::Geo).to receive(:license_allows?).and_return(license_allows)

      render
    end

    context 'when license does not allow' do
      let(:license_allows) { false }

      it 'does not show the Maintenance mode section' do
        expect(rendered).not_to have_css('#js-maintenance-mode-toggle')
      end
    end

    context 'when license allows' do
      it 'shows the Maintenance mode section' do
        expect(rendered).to have_css('#js-maintenance-mode-toggle')
      end
    end
  end

  describe 'prompt user about registration features' do
    context 'with no license and service ping disabled' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'renders registration features prompt', :application_setting_disabled_repository_size_limit
      it_behaves_like 'renders registration features settings link'
    end

    context 'with a valid license and service ping disabled' do
      let(:current_license) { build(:license) }

      before do
        allow(License).to receive(:current).and_return(current_license)
        stub_application_setting(usage_ping_enabled: false)
      end

      it_behaves_like 'does not render registration features prompt', :application_setting_disabled_repository_size_limit
    end
  end

  describe 'add license' do
    let(:current_license) { build(:license) }

    before do
      assign(:new_license, current_license)
      render
    end

    it 'shows the Add License section' do
      expect(rendered).to have_css('#js-add-license-toggle')
    end
  end

  describe 'sign-up restrictions' do
    it 'does not render complexity setting attributes' do
      render

      expect(rendered).to match 'id="js-signup-form"'
      expect(rendered).not_to match 'data-password-lowercase-required'
    end

    context 'when password_complexity license is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      it 'renders complexity setting attributes' do
        render

        expect(rendered).to match ' data-password-lowercase-required='
        expect(rendered).to match ' data-password-number-required='
      end
    end
  end
end
