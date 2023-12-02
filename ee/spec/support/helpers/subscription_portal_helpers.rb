# frozen_string_literal: true

module SubscriptionPortalHelpers
  include StubRequests

  def stub_signing_key
    key = OpenSSL::PKey::RSA.new(2048)

    stub_application_setting(customers_dot_jwt_signing_key: key)
  end

  def stub_eoa_eligibility_request(namespace_id, eligible = false, free_upgrade_plan_id = nil, assisted_upgrade_plan_id = nil)
    stub_full_request(EE::SUBSCRIPTIONS_GRAPHQL_URL, method: :post)
      .with(
        body: "{\"query\":\"{\\n  subscription(namespaceId: \\\"#{namespace_id}\\\") {\\n    eoaStarterBronzeEligible\\n    assistedUpgradePlanId\\n    freeUpgradePlanId\\n  }\\n}\\n\"}",
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'X-Admin-Email' => EE::SUBSCRIPTION_PORTAL_ADMIN_EMAIL,
          'X-Admin-Token' => EE::SUBSCRIPTION_PORTAL_ADMIN_TOKEN
        }
      )
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: stubbed_eoa_eligibility_response_body(eligible, free_upgrade_plan_id, assisted_upgrade_plan_id)
      )
  end

  def billing_plans_data
    Gitlab::Json.parse(plans_fixture.read).map do |data|
      data.deep_symbolize_keys
    end
  end

  def stub_billing_plans(namespace_id, plan = 'free', plans_data = nil, raise_error: nil)
    stub = stub_full_request("#{EE::SUBSCRIPTIONS_GITLAB_PLANS_URL}?namespace_id=#{namespace_id}&plan=#{plan}")
             .with(headers: { 'Accept' => 'application/json' })
    if raise_error
      stub.to_raise(raise_error)
    else
      stub.to_return(status: 200, body: plans_data || plans_fixture)
    end
  end

  def stub_subscription_request_seat_usage(eligible)
    stub_request(:post, EE::SUBSCRIPTIONS_GRAPHQL_URL)
    .to_return(status: 200, body: {
      "data": {
        "subscription": {
          "eligibleForSeatUsageAlerts": eligible
        }
      }
    }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  private

  def plans_fixture
    File.new(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json'))
  end

  def stubbed_eoa_eligibility_response_body(eligible, free_upgrade_plan_id, assisted_upgrade_plan_id)
    {
      "data": {
        "subscription": {
          "eoaStarterBronzeEligible": eligible,
          "assistedUpgradePlanId": free_upgrade_plan_id,
          "freeUpgradePlanId": assisted_upgrade_plan_id
        }
      }
    }.to_json
  end
end
