# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  include Devise::Test::ControllerHelpers
  let(:expected_keys) { UserDetail.registration_objectives.keys - ['joining_team'] }

  describe '#shuffled_registration_objective_options' do
    subject(:shuffled_options) { helper.shuffled_registration_objective_options }

    it 'has values that match all UserDetail registration objective keys' do
      shuffled_option_values = shuffled_options.map { |item| item.last }

      expect(shuffled_option_values).to contain_exactly(*expected_keys)
    end

    it '"other" is always the last option' do
      expect(shuffled_options.last).to eq(['A different reason', 'other'])
    end
  end

  describe '#registration_verification_enabled?' do
    let_it_be(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    subject(:action) { helper.registration_verification_enabled? }

    context 'when experiment is candidate' do
      before do
        stub_experiments(registration_verification: :candidate)
      end

      it { is_expected.to eq(true) }
    end

    context 'when experiment is control' do
      before do
        stub_experiments(registration_verification: :control)
      end

      it { is_expected.to be_falsey }
    end

    it_behaves_like 'tracks assignment and records the subject', :registration_verification, :user do
      subject { current_user }
    end
  end

  describe '#registration_verification_data' do
    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(params))
      allow(helper).to receive(:current_user).and_return(build(:user))
    end

    context 'with `learn_gitlab_project_id` parameter present' do
      let(:params) { { learn_gitlab_project_id: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data)
          .to eq(next_step_url: helper.trial_getting_started_users_sign_up_welcome_path(params))
      end
    end

    context 'with `project_id` parameter present' do
      let(:params) { { project_id: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data)
          .to eq(next_step_url: helper.continuous_onboarding_getting_started_users_sign_up_welcome_path(params))
      end
    end

    context 'with `offer_trial` parameter present' do
      let(:params) { { offer_trial: 'true' } }

      it 'return expected data' do
        expect(helper.registration_verification_data)
          .to eq(next_step_url: helper.new_trial_path)
      end
    end

    context 'with no relevant parameters present' do
      let(:params) { { xxx: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data).to eq(next_step_url: helper.root_path)
      end
    end
  end

  describe '#credit_card_verification_data' do
    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
    end

    it 'returns the expected data' do
      expect(helper.credit_card_verification_data).to eq(
        {
          completed: 'false',
          iframe_url: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_URL,
          allowed_origin: ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
        }
      )
    end
  end

  describe '#arkose_labs_data' do
    before do
      allow(::Arkose::Settings).to receive(:arkose_public_api_key).and_return('api-key')
      allow(::Arkose::Settings).to receive(:arkose_labs_domain).and_return('domain')
    end

    subject(:data) { helper.arkose_labs_data }

    it { is_expected.to eq({ api_key: 'api-key', domain: 'domain' }) }

    context 'when :arkose_labs_signup_challenge is disabled' do
      before do
        stub_feature_flags(arkose_labs_signup_challenge: false)
      end

      it { is_expected.to eq({}) }
    end
  end
end
