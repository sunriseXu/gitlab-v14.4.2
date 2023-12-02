# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::PreEnforcementAlertComponent, :saas, type: :component do
  using RSpec::Parameterized::TableSyntax

  let(:storage_enforcement_date) { Date.today + 31 }

  context 'with a free group' do
    let_it_be(:group) { create(:group_with_plan, :with_root_storage_statistics, plan: :free_plan) }
    let_it_be_with_refind(:user) { create(:user) }

    subject(:component) { described_class.new(context: group, user: user) }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)
      group.root_storage_statistics.update!(
        storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
      )
      allow(group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
    end

    context 'when user is allowed to see and dismiss' do
      before do
        group.add_maintainer(user)
      end

      it 'includes the storage_enforcement_date in the banner text' do
        render_inline(component)

        expect(page).to have_text "Effective #{storage_enforcement_date}, namespace storage limits will apply"
      end

      it 'includes the namespace name in the banner text' do
        render_inline(component)

        expect(page).to have_text group.name
      end

      describe 'alert links' do
        it 'includes the rollout_docs_link in the banner text' do
          render_inline(component)

          expect(page).to have_link(
            'rollout schedule for this change',
            href: help_page_path(
              'user/usage_quotas',
              anchor: 'namespace-storage-limit-enforcement-schedule'
            )
          )
        end

        it 'includes the learn_more_link in the banner text' do
          render_inline(component)

          expect(page).to have_link(
            'Learn more',
            href: help_page_path(
              'user/usage_quotas',
              anchor: 'manage-your-storage-usage'
            )
          )
        end

        it 'includes the faq_link in the banner text' do
          render_inline(component)

          expect(page).to have_link(
            'FAQ',
            href: "#{Gitlab::Saas.about_pricing_url}faq-efficient-free-tier/" \
                  "#storage-limits-on-gitlab-saas-free-tier"
          )
        end
      end

      it 'includes used_storage in the banner text' do
        render_inline(component)

        storage_size = ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP / 1.gigabyte
        expect(page).to have_text "The namespace is currently using #{storage_size} GB of namespace storage"
      end

      it 'renders the correct callout data' do
        render_inline(component)

        expect(page).to have_css("[data-feature-id='storage_enforcement_banner_first_enforcement_threshold']")
        expect(page).to have_css("[data-dismiss-endpoint='#{group_callouts_path}']")
        expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
      end

      context 'with different callout feature ids' do
        where(:callout_feature_id, :storage_enforcement_date_threshold) do
          :storage_enforcement_banner_first_enforcement_threshold | 31
          :storage_enforcement_banner_second_enforcement_threshold | 25
          :storage_enforcement_banner_third_enforcement_threshold | 12
          :storage_enforcement_banner_fourth_enforcement_threshold | 5
        end

        with_them do
          let(:storage_enforcement_date) { Date.today + storage_enforcement_date_threshold }

          it 'renders the correct callout data' do
            render_inline(component)

            expect(page).to have_css("[data-feature-id='#{callout_feature_id}']")
          end
        end
      end

      context 'when user has dismissed banner' do
        before do
          create(
            :group_callout,
            user: user,
            group: group,
            feature_name: 'storage_enforcement_banner_first_enforcement_threshold'
          )
        end

        it 'does not render' do
          render_inline(component)

          expect(page).not_to have_css('.js-storage-enforcement-banner')
        end
      end
    end

    context 'when user is not allowed to dismiss' do
      it 'does not render' do
        render_inline(component)

        expect(page).not_to have_css('.js-storage-enforcement-banner')
      end
    end

    context 'when group does not meet the criteria to render the alert' do
      it 'does not render' do
        allow(::EE::Gitlab::Namespaces::Storage::Enforcement).to receive(:show_pre_enforcement_banner).and_return(false)
        render_inline(component)

        expect(page).not_to have_css('.js-storage-enforcement-banner')
      end
    end
  end
end
