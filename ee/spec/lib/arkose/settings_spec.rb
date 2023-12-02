# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::Settings do
  describe '.arkose_public_api_key' do
    subject { described_class.arkose_public_api_key }

    context 'when set in application settings' do
      let(:setting_value) { 'setting_public_key' }

      before do
        stub_application_setting(arkose_labs_public_api_key: setting_value)
      end

      it { is_expected.to eq setting_value }
    end

    context 'when NOT set in application settings' do
      let(:env_var_value) { 'env_var_public_key' }

      before do
        stub_env('ARKOSE_LABS_PUBLIC_KEY', env_var_value)
      end

      it { is_expected.to eq env_var_value }
    end
  end

  describe '.arkose_private_api_key' do
    subject { described_class.arkose_private_api_key }

    context 'when set in application settings' do
      let(:setting_value) { 'setting_value' }

      before do
        stub_application_setting(arkose_labs_private_api_key: setting_value)
      end

      it { is_expected.to eq setting_value }
    end

    context 'when NOT set in application settings' do
      let(:env_var_value) { 'env_var_value' }

      before do
        stub_env('ARKOSE_LABS_PRIVATE_KEY', env_var_value)
      end

      it { is_expected.to eq env_var_value }
    end
  end

  describe '.arkose_labs_domain' do
    subject { described_class.arkose_labs_domain }

    let(:setting_value) { 'setting_value' }

    before do
      stub_application_setting(arkose_labs_namespace: setting_value)
    end

    it { is_expected.to eq "#{setting_value}-api.arkoselabs.com" }
  end
end
