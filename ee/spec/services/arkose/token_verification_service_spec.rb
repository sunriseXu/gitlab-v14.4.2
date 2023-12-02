# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::TokenVerificationService do
  let(:user) { create(:user) }
  let(:session_token) { '22612c147bb418c8.2570749403' }
  let(:service) { described_class.new(session_token: session_token, user: user) }
  let(:verify_api_url) { "https://verify-api.arkoselabs.com/api/v4/verify/" }
  let(:arkose_labs_private_api_key) { 'foo' }

  subject { service.execute }

  before do
    stub_request(:post, verify_api_url)
      .with(
        body: /.*/,
        headers: {
          'Accept' => '*/*'
        }
      ).to_return(
        status: 200,
        body: arkose_ec_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#execute' do
    shared_examples_for 'interacting with Arkose verify API' do |url|
      let(:verify_api_url) { url }

      context 'when the user did not solve the challenge' do
        let(:arkose_ec_response) do
          Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/failed_ec_response.json')))
        end

        it 'returns an error response' do
          expect(subject).to be_error
        end

        it 'returns an error message' do
          expect(subject.message).to eq 'Captcha was not solved'
        end
      end

      context 'when feature arkose_labs_prevent_login is enabled' do
        shared_examples 'returns success response with the correct payload' do
          let(:mock_response) { Arkose::VerifyResponse.new(arkose_ec_response) }

          before do
            allow(Arkose::VerifyResponse).to receive(:new).with(arkose_ec_response).and_return(mock_response)
          end

          it 'returns a success response' do
            expect(subject).to be_success
          end

          it "returns payload with correct :low_risk value" do
            expect(subject.payload[:low_risk]).to eq is_low_risk
          end

          it 'includes the json response in the payload' do
            expect(subject.payload[:response]).to eq mock_response
          end
        end

        context 'when the user solved the challenge' do
          context 'when the risk score is low' do
            let(:is_low_risk) { true }

            let(:arkose_ec_response) do
              Gitlab::Json.parse(
                File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json'))
              )
            end

            it 'makes a request to the Verify API' do
              subject

              expect(WebMock).to have_requested(:post, verify_api_url)
            end

            it_behaves_like 'returns success response with the correct payload'

            it 'logs Arkose verify response' do
              allow(Gitlab::AppLogger).to receive(:info)
              allow(Gitlab::ApplicationContext).to receive(:current).and_return(
                { 'correlation_id': 'be025cf83013ac4f52ffd2bf712b11a2' }
              )

              subject

              expect(Gitlab::AppLogger).to have_received(:info).with(
                correlation_id: 'be025cf83013ac4f52ffd2bf712b11a2',
                message: 'Arkose verify response',
                response: arkose_ec_response,
                username: user.username,
                'arkose.session_id': '22612c147bb418c8.2570749403',
                'arkose.global_score': '0',
                'arkose.global_telltale_list': [],
                'arkose.custom_score': '0',
                'arkose.custom_telltale_list': [],
                'arkose.risk_band': 'Low',
                'arkose.risk_category': 'NO-THREAT'
              )
            end

            it "records user's Arkose data" do
              mock_response = Arkose::VerifyResponse.new(arkose_ec_response)
              expect(Arkose::VerifyResponse).to receive(:new).with(arkose_ec_response).and_return(mock_response)

              expect_next_instance_of(Arkose::RecordUserDataService, response: mock_response, user: user) do |service|
                expect(service).to receive(:execute)
              end

              subject
            end

            context 'when the session is allowlisted' do
              let(:is_low_risk) { true }

              let(:arkose_ec_response) do
                json = Gitlab::Json.parse(
                  File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json'))
                )
                json['session_details']['telltale_list'].push(Arkose::VerifyResponse::ALLOWLIST_TELLTALE)
                json
              end

              it_behaves_like 'returns success response with the correct payload'
            end

            context 'when the risk score is high' do
              let(:is_low_risk) { false }

              let(:arkose_ec_response) do
                Gitlab::Json.parse(
                  File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json'))
                )
              end

              it_behaves_like 'returns success response with the correct payload'
            end
          end
        end

        context 'when the response does not include the risk session' do
          context 'when the user solved the challenge' do
            let(:is_low_risk) { true }

            let(:arkose_ec_response) do
              Gitlab::Json.parse(
                File.read(
                  Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_without_session_risk.json')
                )
              )
            end

            it_behaves_like 'returns success response with the correct payload'
          end

          context 'when the user did not solve the challenge' do
            let(:arkose_ec_response) do
              Gitlab::Json.parse(
                File.read(Rails.root.join('ee/spec/fixtures/arkose/failed_ec_response_without_risk_session.json'))
              )
            end

            it 'returns an error response' do
              expect(subject).to be_error
            end

            it 'returns an error message' do
              expect(subject.message).to eq 'Captcha was not solved'
            end
          end
        end
      end

      shared_examples 'returns success response with correct payload and logs the error' do
        it 'returns a success response' do
          expect(subject).to be_success
        end

        it 'returns { low_risk: true } payload' do
          expect(subject.payload[:low_risk]).to eq true
        end

        it 'does not include the json response in the payload' do
          expect(subject.payload[:response]).to be_nil
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with(a_string_matching(/Error verifying user on Arkose: /))

          subject
        end
      end

      context 'when response from Arkose is not what we expect' do
        # For example: https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/54

        let(:arkose_ec_response) { 'unexpected_from_arkose' }

        it_behaves_like 'returns success response with correct payload and logs the error'
      end

      context 'when an error occurs during the Arkose request' do
        let(:arkose_ec_response) { {} }

        before do
          allow(Gitlab::HTTP).to receive(:perform_request).and_raise(Errno::ECONNREFUSED.new('bad connection'))
        end

        it_behaves_like 'returns success response with correct payload and logs the error'
      end

      context 'when user is nil' do
        let(:user) { nil }
        let(:arkose_ec_response) do
          Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
        end

        it 'logs Arkose verify response without username' do
          allow(Gitlab::AppLogger).to receive(:info)
          allow(Gitlab::ApplicationContext).to receive(:current).and_return(
            { 'correlation_id': 'be025cf83013ac4f52ffd2bf712b11a2' }
          )

          subject

          expect(Gitlab::AppLogger).to have_received(:info).with(
            correlation_id: 'be025cf83013ac4f52ffd2bf712b11a2',
            message: 'Arkose verify response',
            response: arkose_ec_response,
            'arkose.session_id': '22612c147bb418c8.2570749403',
            'arkose.global_score': '0',
            'arkose.global_telltale_list': [],
            'arkose.custom_score': '0',
            'arkose.custom_telltale_list': [],
            'arkose.risk_band': 'Low',
            'arkose.risk_category': 'NO-THREAT'
          )
        end
      end
    end

    context 'when arkose_labs_prevent_login feature flag is enabled' do
      before do
        stub_application_setting(arkose_labs_private_api_key: arkose_labs_private_api_key)
        stub_application_setting(arkose_labs_namespace: "gitlab")
      end

      it_behaves_like 'interacting with Arkose verify API', "https://gitlab-verify.arkoselabs.com/api/v4/verify/"
    end

    context 'when feature arkose_labs_prevent_login is disabled' do
      before do
        stub_feature_flags(arkose_labs_prevent_login: false)
      end

      context 'when the risk score is high' do
        let(:arkose_ec_response) do
          Gitlab::Json.parse(
            File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response_high_risk.json'))
          )
        end

        it 'returns a success response' do
          expect(subject).to be_success
        end

        it 'returns { low_risk: true } payload' do
          expect(subject.payload[:low_risk]).to eq true
        end
      end
    end
  end
end
