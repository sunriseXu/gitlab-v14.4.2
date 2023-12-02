# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SubscriptionPortal::Clients::Rest do
  let(:client) { Gitlab::SubscriptionPortal::Client }
  let(:http_response) { nil }
  let(:http_method) { :post }
  let(:error_message) { 'Our team has been notified. Please try again.' }
  let(:gitlab_http_response) do
    double(
      code: http_response.code,
      response: http_response,
      body: {},
      parsed_response: {},
      message: 'message'
    )
  end

  shared_examples 'when response is successful' do
    let(:http_response) { Net::HTTPSuccess.new(1.0, '201', 'OK') }

    it 'has a successful status' do
      allow(Gitlab::HTTP).to receive(http_method).and_return(gitlab_http_response)

      expect(subject[:success]).to eq(true)
    end
  end

  shared_examples 'when http call raises an exception' do
    it 'overrides the error message' do
      exception = Gitlab::HTTP::HTTP_ERRORS.first.new
      allow(Gitlab::HTTP).to receive(http_method).and_raise(exception)

      result = subject

      expect(result[:success]).to eq(false)
      expect(result[:data][:errors]).to eq(error_message)
    end
  end

  shared_examples 'when response code is 422' do
    let(:http_response) { Net::HTTPUnprocessableEntity.new(1.0, '422', 'Error') }

    it 'has a unprocessable entity status' do
      allow(Gitlab::ErrorTracking).to receive(:log_exception)
      allow(Gitlab::HTTP).to receive(http_method).and_return(gitlab_http_response)

      expect(subject[:success]).to eq(false)

      expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(
        instance_of(::Gitlab::SubscriptionPortal::Client::ResponseError),
        { status: '422', message: 'message', body: {} }
      )
    end
  end

  shared_examples 'when response code is 500' do
    let(:http_response) { Net::HTTPServerError.new(1.0, '500', 'Error') }

    it 'has a server error status' do
      allow(Gitlab::ErrorTracking).to receive(:log_exception)
      allow(Gitlab::HTTP).to receive(http_method).and_return(gitlab_http_response)

      expect(subject[:success]).to eq(false)

      expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(
        instance_of(::Gitlab::SubscriptionPortal::Client::ResponseError),
        { status: '500', message: 'message', body: {} }
      )
    end
  end

  describe '#generate_trial' do
    subject do
      client.generate_trial({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'

    it "nests in the trial_user param if needed" do
      expect(client).to receive(:http_post).with('trials', anything, { trial_user: { foo: 'bar' } })

      client.generate_trial(foo: 'bar')
    end
  end

  describe '#generate_lead' do
    subject do
      client.generate_lead({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#extend_reactivate_trial' do
    let(:http_method) { :put }

    subject do
      client.extend_reactivate_trial({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#create_subscription' do
    subject do
      client.create_subscription({}, 'customer@mail.com', 'token')
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#create_customer' do
    subject do
      client.create_customer({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#payment_form_params' do
    subject do
      client.payment_form_params('cc')
    end

    let(:http_method) { :get }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#payment_method' do
    subject do
      client.payment_method('1')
    end

    let(:http_method) { :get }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#validate_payment_method' do
    subject do
      client.validate_payment_method('test_payment_method_id', {})
    end

    let(:http_method) { :post }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end

  describe '#customers_oauth_app_uid' do
    subject do
      client.customers_oauth_app_uid
    end

    let(:http_method) { :get }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
    it_behaves_like 'when http call raises an exception'
  end
end
