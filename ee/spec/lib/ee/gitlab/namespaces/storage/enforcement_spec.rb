# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::Gitlab::Namespaces::Storage::Enforcement, :saas do
  describe '.enforce_limit?' do
    before do
      stub_feature_flags(
        namespace_storage_limit: group,
        enforce_storage_limit_for_free: group,
        enforce_storage_limit_for_paid: group,
        namespace_storage_limit_bypass_date_check: false
      )
      stub_application_setting(
        enforce_namespace_storage_limit: true,
        automatic_purchased_storage_allocation: true
      )
      stub_enforcement_date(Date.today)
      stub_effective_date(group.gitlab_subscription&.start_date || 1.year.ago.to_date)
    end

    context 'with a free plan' do
      let_it_be(:group) { create(:group_with_plan, plan: :free_plan) }

      it 'returns true when namespace storage limits are enforced for the namespace' do
        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the enforce_storage_limit_for_paid feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_paid: false)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the namespace_storage_limit_bypass_date_check flag is enabled regardless of dates' do
        stub_enforcement_date(Date.tomorrow)
        stub_effective_date(group.gitlab_subscription.start_date + 1.day)
        stub_feature_flags(namespace_storage_limit_bypass_date_check: group)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns false when the namespace_storage_limit feature flag is disabled' do
        stub_feature_flags(namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the enforce_storage_limit_for_free feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_free: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the enforce_namespace_storage_limit application setting is disabled' do
        stub_application_setting(enforce_namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the automatic_purchased_storage_allocation application setting is disabled' do
        stub_application_setting(automatic_purchased_storage_allocation: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the enforcement date is in the future' do
        stub_enforcement_date(Date.tomorrow)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the effective date is after the subscription start date' do
        stub_effective_date(group.gitlab_subscription.start_date + 1.day)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end
    end

    context 'with a paid plan' do
      let_it_be(:group) { create(:group_with_plan, plan: :ultimate_plan) }

      it 'returns true when namespace storage limits are enforced for the namespace' do
        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the enforce_storage_limit_for_free feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_free: false)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the namespace_storage_limit_bypass_date_check flag is enabled regardless of dates' do
        stub_enforcement_date(Date.tomorrow)
        stub_effective_date(group.gitlab_subscription.start_date + 1.day)
        stub_feature_flags(namespace_storage_limit_bypass_date_check: group)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns false when the enforce_storage_limit_for_paid feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_paid: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the namespace_storage_limit feature flag is disabled' do
        stub_feature_flags(namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the enforce_namespace_storage_limit application setting is disabled' do
        stub_application_setting(enforce_namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the automatic_purchased_storage_allocation application setting is disabled' do
        stub_application_setting(automatic_purchased_storage_allocation: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the enforcement date is in the future' do
        stub_enforcement_date(Date.tomorrow)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the effective date is after the subscription start date' do
        stub_effective_date(group.gitlab_subscription.start_date + 1.day)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end
    end

    context 'with an open source plan' do
      let_it_be(:group) { create(:group_with_plan, plan: :opensource_plan) }

      it 'returns false even when namespace storage limits are enforced' do
        expect(described_class.enforce_limit?(group)).to eq(false)
      end
    end

    context 'without a plan' do
      let(:group) { create(:group) }

      it 'returns true when namespace storage limits are enforced for the namespace' do
        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the enforce_storage_limit_for_paid feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_paid: false)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns true when the namespace_storage_limit_bypass_date_check flag is enabled regardless of dates' do
        stub_enforcement_date(Date.tomorrow)
        stub_effective_date(Date.tomorrow)
        stub_feature_flags(namespace_storage_limit_bypass_date_check: group)

        expect(described_class.enforce_limit?(group)).to eq(true)
      end

      it 'returns false when the namespace_storage_limit feature flag is disabled' do
        stub_feature_flags(namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the enforce_storage_limit_for_free feature flag is disabled' do
        stub_feature_flags(enforce_storage_limit_for_free: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the enforce_namespace_storage_limit application setting is disabled' do
        stub_application_setting(enforce_namespace_storage_limit: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false when the automatic_purchased_storage_allocation application setting is disabled' do
        stub_application_setting(automatic_purchased_storage_allocation: false)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the enforcement date is in the future' do
        stub_enforcement_date(Date.tomorrow)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end

      it 'returns false if the effective date is in the future' do
        stub_effective_date(Date.tomorrow)

        expect(described_class.enforce_limit?(group)).to eq(false)
      end
    end

    context 'with a subgroup' do
      let_it_be(:group) { create(:group_with_plan, plan: :free_plan) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      it 'returns true when namespace storage limits are enforced for the root namespace' do
        expect(described_class.enforce_limit?(subgroup)).to eq(true)
      end
    end
  end

  describe 'ENFORCEMENT_DATE' do
    it 'is 100 years from today' do
      expect(described_class::ENFORCEMENT_DATE).to eq(100.years.from_now.to_date)
    end
  end

  describe 'EFFECTIVE_DATE' do
    it 'is 99 years from today' do
      expect(described_class::EFFECTIVE_DATE).to eq(99.years.from_now.to_date)
    end
  end

  def stub_enforcement_date(date)
    stub_const('::EE::Gitlab::Namespaces::Storage::Enforcement::ENFORCEMENT_DATE', date)
  end

  def stub_effective_date(date)
    stub_const('::EE::Gitlab::Namespaces::Storage::Enforcement::EFFECTIVE_DATE', date)
  end
end
