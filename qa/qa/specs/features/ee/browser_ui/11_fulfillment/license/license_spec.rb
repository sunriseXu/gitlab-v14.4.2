# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, :skip_live_env, except: { job: 'review-qa-*' } do
    let(:user) { 'GitLab QA' }
    let(:company) { 'QA User' }
    let(:user_count) { 10_000 }
    let(:plan) { ULTIMATE_SELF_MANAGED }

    context 'Active license details' do
      before do
        Flow::Login.sign_in_as_admin
        Gitlab::Page::Admin::Subscription.perform(&:visit)
      end

      it 'shows up in subscription page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347607' do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          aggregate_failures do
            expect { subscription.subscription_details? }.to eventually_be_truthy.within(max_duration: 60)
            expect(subscription.name).to eq(user)
            expect(subscription.company).to include(company)
            expect(subscription.plan).to eq(plan[:name].capitalize)
            expect(subscription.users_in_subscription).to eq(user_count.to_s)
            expect(subscription).to have_subscription_record(plan, user_count, LICENSE_TYPE[:legacy_license])
          end
        end
      end
    end
  end
end
