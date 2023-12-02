# frozen_string_literal: true

module QA
  module Flow
    module UserOnboarding
      extend self

      def onboard_user
        Page::Registration::Welcome.perform do |welcome_page|
          if welcome_page.has_get_started_button?
            welcome_page.select_role('Other')
            welcome_page.choose_setup_for_company_if_available
            welcome_page.click_get_started_button
          end
        end
      end
    end
  end
end

QA::Flow::UserOnboarding.prepend_mod_with('Flow::UserOnboarding', namespace: QA)
