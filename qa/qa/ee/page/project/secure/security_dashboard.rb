# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class SecurityDashboard < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_list.vue' do
              element :vulnerability
              element :vulnerability_report_checkbox_all
              element :false_positive_vulnerability
              element :vulnerability_remediated_badge_content
              element :vulnerability_status_content
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/selection_summary.vue' do
              element :vulnerability_card_status_dropdown
              element :change_status_button
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/csv_export_button.vue' do
              element :export_csv_modal_button
            end

            def initialize
              super
              close_export_csv_modal
            end

            def has_vulnerability?(description:)
              has_element?(:vulnerability, vulnerability_description: description)
            end

            def has_false_positive_vulnerability?
              has_element?(:false_positive_vulnerability)
            end

            def click_vulnerability(description:)
              return false unless has_vulnerability?(description: description)

              click_element(:vulnerability, vulnerability_description: description)
            end

            def select_all_vulnerabilities
              check_element(:vulnerability_report_checkbox_all, true)
            end

            def select_single_vulnerability(vulnerability_name)
              click_element(:vulnerability_status_content, status_description: vulnerability_name)
            end

            def close_export_csv_modal
              click_element(:export_csv_modal_button) if has_element?(:export_csv_modal_button, wait: 0.5)
            end

            def change_state(status)
              click_element(:vulnerability_card_status_dropdown)
              click_element("item_status_#{status.downcase}")
              click_element(:change_status_button)
            end

            def has_remediated_badge?(vulnerability_name)
              has_element?(:vulnerability_remediated_badge_content, activity_description: vulnerability_name)
            end
          end
        end
      end
    end
  end
end
