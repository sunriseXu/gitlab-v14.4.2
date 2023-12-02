# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationController, :clean_gitlab_redis_sessions, :clean_gitlab_redis_rate_limiting do
  include SessionHelpers

  let_it_be(:unconfirmed_user) { create(:user, :unconfirmed) }
  let_it_be(:confirmed_user) { create(:user) }

  shared_examples 'it requires an unconfirmed user' do
    before do
      stub_session(verification_user_id: user&.id)
      do_request
    end

    subject { response }

    context 'when session contains no `verification_user_id`' do
      let_it_be(:user) { nil }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from a confirmed user' do
      let_it_be(:user) { confirmed_user }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when session contains a `verification_user_id` from an unconfirmed user' do
      let_it_be(:user) { unconfirmed_user }

      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe '#show' do
    subject(:do_request) { get identity_verification_path }

    it_behaves_like 'it requires an unconfirmed user'

    it 'renders template show with layout minimal' do
      stub_session(verification_user_id: unconfirmed_user.id)

      do_request

      expect(response).to render_template('show', layout: 'minimal')
    end
  end

  describe '#verify_email_code' do
    let_it_be(:params) { { identity_verification: { code: '123456' } } }
    let_it_be(:service_response) { { status: :success } }

    subject(:do_request) { post verify_email_code_identity_verification_path(params) }

    before do
      allow_next_instance_of(::Users::EmailVerification::ValidateTokenService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end
    end

    it_behaves_like 'it requires an unconfirmed user'

    context 'when validation was successful' do
      it 'confirms the user' do
        stub_session(verification_user_id: unconfirmed_user.id)

        freeze_time do
          expect { do_request }.to change { unconfirmed_user.reload.confirmed_at }.from(nil).to(Time.current)
        end
      end

      it 'accepts pending invitations' do
        member_invite = create(:project_member, :invited, invite_email: unconfirmed_user.email)
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(member_invite.reload).not_to be_invite
      end

      it 'signs in the user' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(request.env['warden']).to be_authenticated
      end

      it 'logs the successful attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Identity Verification',
            event: 'Successful',
            username: unconfirmed_user.username
          )
        )

        stub_session(verification_user_id: unconfirmed_user.id)

        do_request
      end

      it 'renders the result as json including a redirect URL' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(response.body).to eq(service_response.merge(redirect_url: users_successful_verification_path).to_json)
      end
    end

    context 'when failing to validate' do
      let_it_be(:service_response) { { status: :failure, reason: 'reason', message: 'message' } }

      it 'logs the failed attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Identity Verification',
            event: 'Failed Attempt',
            username: unconfirmed_user.username,
            reason: service_response[:reason]
          )
        )

        stub_session(verification_user_id: unconfirmed_user.id)
        do_request
      end

      it 'renders the result as json' do
        stub_session(verification_user_id: unconfirmed_user.id)

        do_request

        expect(response.body).to eq(service_response.to_json)
      end
    end
  end

  describe '#resend_email_code' do
    subject(:do_request) { post resend_email_code_identity_verification_path }

    it_behaves_like 'it requires an unconfirmed user'

    context 'when rate limited' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
          .with(:email_verification_code_send, scope: unconfirmed_user).and_return(true)
        stub_session(verification_user_id: unconfirmed_user.id)
        do_request
      end

      it 'renders the result as json' do
        expect(response.body).to eq({
          status: :failure,
          message: format(s_("IdentityVerification|You've reached the maximum amount of resends. Wait %{interval} "\
            'and try again.'), interval: 'about 1 hour')
        }.to_json)
      end
    end

    context 'when successful' do
      let_it_be(:new_token) { '123456' }
      let_it_be(:encrypted_token) { Devise.token_generator.digest(User, :confirmation_token, new_token) }

      before do
        allow_next_instance_of(::Users::EmailVerification::GenerateTokenService, attr: :confirmation_token) do |service|
          allow(service).to receive(:generate_token).and_return(new_token)
        end
        stub_session(verification_user_id: unconfirmed_user.id)
      end

      it 'sets the confirmation_sent_at time' do
        freeze_time do
          expect { do_request }.to change { unconfirmed_user.reload.confirmation_sent_at }.to(Time.current)
        end
      end

      it 'sets the confirmation_token to the encrypted custom token' do
        expect { do_request }.to change { unconfirmed_user.reload.confirmation_token }.to(encrypted_token)
      end

      it 'sends the confirmation instructions email' do
        expect(::Notify).to receive(:confirmation_instructions_email)
          .with(unconfirmed_user.email, token: new_token).once.and_call_original

        do_request
      end

      it 'logs the successful attempt' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Identity Verification',
            event: 'Instructions Sent',
            username: unconfirmed_user.username
          )
        )

        do_request
      end

      it 'renders the result as json' do
        do_request

        expect(response.body).to eq({ status: :success }.to_json)
      end
    end
  end
end
