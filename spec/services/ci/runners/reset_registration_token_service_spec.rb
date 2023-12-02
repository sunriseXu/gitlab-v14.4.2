# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetRegistrationTokenService, '#execute' do
  subject(:execute) { described_class.new(scope, current_user).execute }

  let_it_be(:user) { build(:user) }
  let_it_be(:admin_user) { create(:user, :admin) }

  shared_examples 'a registration token reset operation' do
    context 'without user' do
      let(:current_user) { nil }

      it 'does not reset registration token and returns error response' do
        expect(scope).not_to receive(token_reset_method_name)

        expect(execute).to be_error
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { user }

      it 'does not reset registration token and returns error response' do
        expect(scope).not_to receive(token_reset_method_name)

        expect(execute).to be_error
      end
    end

    context 'with admin user', :enable_admin_mode do
      let(:current_user) { admin_user }

      it 'resets registration token and returns value unchanged' do
        expect(scope).to receive(token_reset_method_name).once do
          expect(scope).to receive(token_method_name).once.and_return("#{token_method_name} return value")
        end

        expect(execute).to be_success
        expect(execute.payload[:new_registration_token]).to eq("#{token_method_name} return value")
      end
    end
  end

  context 'with instance scope' do
    let_it_be(:scope) { create(:application_setting) }

    before do
      allow(ApplicationSetting).to receive(:current).and_return(scope)
      allow(ApplicationSetting).to receive(:current_without_cache).and_return(scope)
    end

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_registration_token }
      let(:token_reset_method_name) { :reset_runners_registration_token! }
    end
  end

  context 'with group scope' do
    let_it_be(:scope) { create(:group) }

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_token }
      let(:token_reset_method_name) { :reset_runners_token! }
    end
  end

  context 'with project scope' do
    let_it_be(:scope) { create(:project) }

    it_behaves_like 'a registration token reset operation' do
      let(:token_method_name) { :runners_token }
      let(:token_reset_method_name) { :reset_runners_token! }
    end
  end
end
