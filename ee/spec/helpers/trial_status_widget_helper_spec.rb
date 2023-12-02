# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialStatusWidgetHelper, :saas do
  include TrialStatusWidgetTestHelper

  describe 'data attributes for mounting Vue components', :freeze_time do
    let(:trial_length) { 30 } # days
    let(:trial_days_remaining) { 18 }
    let(:trial_days_used) { trial_length - trial_days_remaining }
    let(:trial_end_date) { Date.current.advance(days: trial_days_remaining) }
    let(:trial_start_date) { Date.current.advance(days: trial_days_remaining - trial_length) }
    let(:trial_percentage_complete) { (trial_length - trial_days_remaining) * 100 / trial_length }

    let_it_be(:group) { create(:group) }

    let(:shared_expected_attrs) do
      {
        container_id: 'trial-status-sidebar-widget',
        days_remaining: trial_days_remaining,
        plan_name: 'Ultimate',
        plans_href: group_billings_path(group)
      }
    end

    before do
      build(:gitlab_subscription, :active_trial,
        namespace: group,
        trial_starts_on: trial_start_date,
        trial_ends_on: trial_end_date
      )
      stub_experiments(group_contact_sales: :control)
      allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService, plan: :free) do |instance|
        allow(instance).to receive(:execute).and_return(
          [
            { 'code' => 'ultimate', 'id' => 'ultimate-plan-id' }
          ])
      end
    end

    describe '#trial_status_popover_data_attrs' do
      let_it_be(:user) { create(:user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      subject(:data_attrs) { helper.trial_status_popover_data_attrs(group) }

      it 'returns the needed data attributes for mounting the popover Vue component' do
        expect(data_attrs).to match(
          shared_expected_attrs.merge(
            group_name: group.name,
            purchase_href: purchase_href(group),
            target_id: shared_expected_attrs[:container_id],
            trial_end_date: trial_end_date
          )
        )
      end

      context 'when group_contact_sales is enabled' do
        before do
          stub_experiments(group_contact_sales: :candidate)
        end

        it 'returns the needed data attributes for mounting the popover Vue component' do
          expect(data_attrs).to match(
            shared_expected_attrs.merge(
              namespace_id: group.id,
              user_name: user.username,
              first_name: user.first_name,
              last_name: user.last_name,
              company_name: user.organization,
              glm_content: 'trial-status-show-group',
              group_name: group.name,
              purchase_href: purchase_href(group),
              target_id: shared_expected_attrs[:container_id],
              trial_end_date: trial_end_date
            )
          )
        end
      end
    end

    describe '#trial_status_widget_data_attrs' do
      before do
        allow(helper).to receive(:image_path).and_return('/image-path/for-file.svg')
      end

      subject(:data_attrs) { helper.trial_status_widget_data_attrs(group) }

      it 'returns the needed data attributes for mounting the widget Vue component' do
        expect(data_attrs).to match(
          shared_expected_attrs.merge(
            trial_days_used: trial_days_used,
            trial_duration: trial_length,
            nav_icon_image_path: '/image-path/for-file.svg',
            percentage_complete: trial_percentage_complete
          )
        )
      end
    end
  end
end
