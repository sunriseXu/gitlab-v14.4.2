# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsHelper do
  using RSpec::Parameterized::TableSyntax

  let(:owner) { create(:user, group_view: :security_dashboard) }
  let(:current_user) { owner }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(owner)
  end

  describe '#render_setting_to_allow_project_access_token_creation?' do
    context 'with self-managed' do
      let_it_be(:parent) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent) }

      before do
        parent.add_owner(owner)
        group.add_owner(owner)
      end

      it 'returns true if group is root' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to be_truthy
      end

      it 'returns false if group is subgroup' do
        expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
      end
    end

    context 'on .com', :saas do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'with a free plan' do
        let_it_be(:group) { create(:group) }

        it 'returns false' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
        end
      end

      context 'with a paid plan' do
        let_it_be(:parent) { create(:group_with_plan, plan: :bronze_plan) }
        let_it_be(:group) { create(:group, parent: parent) }

        before do
          parent.add_owner(owner)
        end

        it 'returns true if group is root' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(parent)).to be_truthy
        end

        it 'returns false if group is subgroup' do
          expect(helper.render_setting_to_allow_project_access_token_creation?(group)).to be_falsey
        end
      end
    end
  end

  describe '#permanent_deletion_date' do
    let(:date) { 2.days.from_now }

    subject { helper.permanent_deletion_date(date) }

    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    it 'returns the sum of the date passed as argument and the deletion_adjourned_period set in application setting' do
      expected_date = date + 5.days

      expect(subject).to eq(expected_date.strftime('%F'))
    end
  end

  describe '#remove_group_message' do
    subject { helper.remove_group_message(group) }

    shared_examples 'permanent deletion message' do
      it 'returns the message related to permanent deletion' do
        expect(subject).to include("You are going to remove #{group.name}")
        expect(subject).to include("Removed groups CANNOT be restored!")
      end
    end

    shared_examples 'delayed deletion message' do
      it 'returns the message related to delayed deletion' do
        expect(subject).to include("The contents of this group, its subgroups and projects will be permanently removed after")
      end
    end

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it_behaves_like 'delayed deletion message'

      context 'group is already marked for deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
        end

        it_behaves_like 'permanent deletion message'
      end

      context 'when group delay deletion is enabled' do
        before do
          stub_application_setting(delayed_group_deletion: true)
        end

        it_behaves_like 'delayed deletion message'
      end

      context 'when group delay deletion is disabled' do
        before do
          stub_application_setting(delayed_group_deletion: false)
        end

        it_behaves_like 'permanent deletion message'
      end

      context 'when group delay deletion is enabled and adjourned deletion period is 0' do
        before do
          stub_application_setting(delayed_group_deletion: true)
          stub_application_setting(deletion_adjourned_period: 0)
        end

        it_behaves_like 'permanent deletion message'
      end
    end

    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it_behaves_like 'permanent deletion message'
    end
  end

  describe '#immediately_remove_group_message' do
    subject { helper.immediately_remove_group_message(group) }

    it 'returns the message related to immediate deletion' do
      expect(subject).to match(/permanently remove.*#{group.path}.*immediately/)
    end
  end

  describe '#show_discover_group_security?' do
    using RSpec::Parameterized::TableSyntax

    where(
      gitlab_com?: [true, false],
      user?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_group?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(helper).to receive(:current_user) { user? ? owner : nil }
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(group).to receive(:licensed_feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_group? }

        expected_value = user? && gitlab_com? && !security_dashboard_feature_available? && can_admin_group?

        expect(helper.show_discover_group_security?(group)).to eq(expected_value)
      end
    end
  end

  describe '#show_group_activity_analytics?' do
    before do
      stub_licensed_features(group_activity_analytics: feature_available)

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
    end

    context 'when feature is not available for group' do
      let(:feature_available) { false }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when current user does not have access to the group' do
      let(:feature_available) { true }
      let(:current_user) { create(:user) }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when feature is available and user has access to it' do
      let(:feature_available) { true }

      it 'returns true' do
        expect(helper.show_group_activity_analytics?).to be true
      end
    end
  end

  describe '#show_delayed_project_removal_setting?' do
    before do
      stub_licensed_features(adjourned_deletion_for_projects_and_groups: licensed?)
    end

    where(:licensed?, :result) do
      true  | true
      false | false
    end

    with_them do
      it { expect(helper.show_delayed_project_removal_setting?(group)).to be result }
    end
  end

  describe '#show_product_purchase_success_alert?' do
    describe 'when purchased_product is present' do
      before do
        allow(controller).to receive(:params) { { purchased_product: product } }
      end

      where(:product, :result) do
        'product' | true
        ''        | false
        nil       | false
      end

      with_them do
        it { expect(helper.show_product_purchase_success_alert?).to be result }
      end
    end

    describe 'when purchased_product is not present' do
      it { expect(helper.show_product_purchase_success_alert?).to be false }
    end
  end

  describe '#usage_quotas_storage_app_data' do
    it 'returns the needed data in correct format' do
      expect(helper.usage_quotas_storage_app_data(group)).to eq({
        additional_repo_storage_by_namespace: "false",
        buy_addon_target_attr: nil,
        default_per_page: 20,
        is_free_namespace: "true",
        is_temporary_storage_increase_visible: "false",
        namespace_path: group.path,
        purchase_storage_url: nil,
        storage_limit_enforced: "false"
      })
    end
  end

  describe '#group_seats_usage_quota_app_data' do
    subject(:group_seats_usage_quota_app_data) { helper.group_seats_usage_quota_app_data(group) }

    let(:user_cap_applied) { true }
    let(:enforce_free_user_cap) { false }
    let(:preview_free_user_cap) { false }
    let(:data) do
      {
        namespace_id: group.id,
        namespace_name: group.name,
        seat_usage_export_path: group_seat_usage_path(group, format: :csv),
        pending_members_page_path: pending_members_group_usage_quotas_path(group),
        pending_members_count: ::Member.in_hierarchy(group).with_state("awaiting").count,
        add_seats_href: ::Gitlab::SubscriptionPortal.add_extra_seats_url(group.id),
        has_no_subscription: group.has_free_or_no_subscription?.to_s,
        max_free_namespace_seats: 10,
        explore_plans_path: group_billings_path(group),
        free_user_cap_enabled: 'false',
        preview_free_user_cap: 'false'
      }
    end

    before do
      stub_const("::Namespaces::FreeUserCap::FREE_USER_LIMIT", 10)
      expect(group).to receive(:user_cap_available?).and_return(user_cap_applied)

      expect_next_instance_of(::Namespaces::FreeUserCap::Standard, group) do |instance|
        expect(instance).to receive(:enforce_cap?).and_return(enforce_free_user_cap)
      end
      expect_next_instance_of(::Namespaces::FreeUserCap::Preview, group) do |instance|
        expect(instance).to receive(:enforce_cap?).and_return(preview_free_user_cap)
      end
    end

    context 'when user cap is applied' do
      let(:expected_data) { data.merge({ pending_members_page_path: pending_members_group_usage_quotas_path(group) }) }

      it { is_expected.to eql(expected_data) }
    end

    context 'when user cap is not applied' do
      let(:user_cap_applied) { false }
      let(:expected_data) { data.merge({ pending_members_page_path: nil }) }

      it { is_expected.to eql(expected_data) }
    end

    context 'when free user cap is enforced' do
      let(:enforce_free_user_cap) { true }
      let(:expected_data) { data.merge({ free_user_cap_enabled: 'true' }) }

      it { is_expected.to eql(expected_data) }
    end

    context 'when preview free user cap is enabled' do
      let(:preview_free_user_cap) { true }
      let(:expected_data) { data.merge({ preview_free_user_cap: 'true' }) }

      it { is_expected.to eql(expected_data) }
    end
  end

  describe '#require_verification_for_namespace_creation_enabled?' do
    let(:user_created_at) { RequireVerificationForNamespaceCreationExperiment::EXPERIMENT_START_DATE + 1.hour }
    let(:owner) { create(:user, created_at: user_created_at) }
    let(:variant) { :control }

    subject { helper.require_verification_for_namespace_creation_enabled? }

    before do
      stub_experiments(require_verification_for_namespace_creation: variant)
    end

    context 'when in candidate path' do
      let(:variant) { :candidate }

      it { is_expected.to eq(true) }

      context 'when creating a sub-group' do
        before do
          allow(controller).to receive(:params) { { parent_id: 1 } }
        end

        it { is_expected.to eq(false) }
      end

      context 'when user is admin or auditor' do
        before do
          allow(current_user).to receive(:can_read_all_resources?).and_return(true)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when in control path' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#saml_sso_settings_generate_helper_text' do
    let(:text) { 'some text' }
    let(:result) { "<span class=\"js-helper-text gl-clearfix\">#{text}</span>" }

    specify { expect(helper.saml_sso_settings_generate_helper_text(display_none: false, text: text)).to eq result }
    specify { expect(helper.saml_sso_settings_generate_helper_text(display_none: true, text: text)).to include('gl-display-none') }
  end
end
