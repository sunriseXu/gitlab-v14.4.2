# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/billings/index', :saas, :aggregate_failures do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group_with_plan, plan: :free_plan) }
  let_it_be(:plans_data) { billing_plans_data.map { |plan| Hashie::Mash.new(plan) } }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
    assign(:plans_data, plans_data)
  end

  context 'when the group is the top level' do
    it 'renders the billing plans' do
      render

      expect(rendered).to render_template('_top_level_billing_plan_header')
      expect(rendered).to render_template('shared/billings/_billing_plans')
      expect(rendered).to have_selector('#js-billing-plans')
    end

    context 'with promote_premium_billing_page experiment candidate experience' do
      before do
        stub_experiments(promote_premium_billing_page: :candidate)
      end

      context 'with free plan' do
        it 'renders the candidate billing page experience' do
          render

          expect(rendered).to have_text('is currently using the')
          expect(rendered).to have_text('Not the group')
          expect(rendered).to have_link('Check out all groups', href: dashboard_groups_path)

          page = Capybara.string(rendered)

          # free
          scoped_node = page.find("[data-testid='plan-card-free']")

          expect(scoped_node).to have_content('Your current plan')
          expect(scoped_node).to have_content('Free')
          expect(scoped_node).to have_content('Free forever features for individual users')
          expect(scoped_node).to have_link('Learn more')

          # premium
          scoped_node = page.find("[data-testid='plan-card-premium']")

          expect(scoped_node).to have_content('Recommended')
          expect(scoped_node).to have_content('Premium')
          expect(scoped_node).to have_content('Enhance team productivity and collaboration')
          expect(scoped_node).to have_link('Upgrade to Premium')

          # ultimate
          scoped_node = page.find("[data-testid='plan-card-ultimate']")

          expect(scoped_node).to have_content('Ultimate')
          expect(scoped_node).to have_content('Organization wide security')
          expect(scoped_node).to have_link('Upgrade to Ultimate')

          expect(rendered).to have_link('Start a free Ultimate trial', href: new_trial_path)
        end

        it 'has tracking items set as expected' do
          render

          expect_to_have_tracking(action: 'render')
          expect_to_have_tracking(action: 'click_button', label: 'view_all_groups')
          expect_to_have_tracking(action: 'click_button', label: 'start_trial')
        end

        def expect_to_have_tracking(action:, label: nil)
          css = "[data-track-action='#{action}']"
          css += "[data-track-label='#{label}']" if label
          css += "[data-track-experiment='promote_premium_billing_page']"

          expect(rendered).to have_css(css)
        end
      end

      context 'with a paid plan' do
        let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }

        it 'excludes the plan and show the control billing page experience' do
          render

          expect(rendered).to render_template('_top_level_billing_plan_header')
          expect(rendered).to render_template('shared/billings/_billing_plans')
          expect(rendered).to have_selector('#js-billing-plans')
        end
      end
    end
  end
end
