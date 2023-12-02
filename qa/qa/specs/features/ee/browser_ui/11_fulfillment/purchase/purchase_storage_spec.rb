# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.shared_examples 'Purchase storage' do |purchase_quantity|
    it 'adds additional storage to group namespace' do
      Flow::Purchase.purchase_storage(quantity: purchase_quantity)

      Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
        expected_storage = STORAGE[:storage] * purchase_quantity

        expect { usage_quota.storage_purchase_successful_alert? }.to eventually_be_truthy.within(max_duration: 60, max_attempts: 30)
        expect { usage_quota.purchased_storage_available? }.to eventually_be_truthy.within(max_duration: 120, max_attempts: 60, reload_page: page)
        expect { usage_quota.total_purchased_storage(free_name_space) }.to eventually_eq(expected_storage.to_f).within(max_duration: 120, max_attempts: 60, reload_page: page)
      end
    end
  end

  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    let(:hash) { SecureRandom.hex(4) }
    let(:free_name_space) { true }
    let(:user) do
      Resource::User.fabricate_via_api! do |user|
        user.email = "test-user-#{hash}@gitlab.com"
        user.api_client = Runtime::API::Client.as_admin
        user.hard_delete_on_api_removal = true
      end
    end

    let(:group) do
      Resource::Sandbox.fabricate! do |sandbox|
        sandbox.path = "test-group-fulfillment#{hash}"
        sandbox.api_client = Runtime::API::Client.as_admin
      end
    end

    before do
      Flow::Login.sign_in(as: user)

      Resource::Project.fabricate_via_api! do |project|
        project.name = 'storage'
        project.group = group
        project.initialize_with_readme = true
        project.api_client = Runtime::API::Client.as_admin
      end

      group.visit!
    end

    after do
      user.remove_via_api!
    end

    context 'purchase storage without active subscription', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347571' do
      after do
        group.remove_via_api!
      end

      it_behaves_like 'Purchase storage', 5
    end

    context 'purchase storage with an active subscription', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348472' do
      let(:free_name_space) { false }

      before do
        Flow::Purchase.upgrade_subscription(plan: PREMIUM)
      end

      it_behaves_like 'Purchase storage', 20
    end

    context 'purchase storage with existing CI minutes packs', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348470' do
      before do
        Flow::Purchase.purchase_ci_minutes(quantity: 5)
      end

      after do
        group.remove_via_api!
      end

      it_behaves_like 'Purchase storage', 10
    end
  end
end
