# frozen_string_literal: true

module QA
  module CE
    module Strategy
      extend self

      def perform_before_hooks
        if QA::Runtime::Env.admin_personal_access_token.present?
          QA::Resource::PersonalAccessTokenCache.set_token_for_username(QA::Runtime::User.admin_username,
            QA::Runtime::Env.admin_personal_access_token)
        end

        if QA::Runtime::Env.personal_access_token.present? && QA::Runtime::Env.user_username.present?
          QA::Resource::PersonalAccessTokenCache.set_token_for_username(QA::Runtime::Env.user_username,
            QA::Runtime::Env.personal_access_token)
        end

        # The login page could take some time to load the first time it is visited.
        # We visit the login page and wait for it to properly load only once before the tests.
        QA::Runtime::Logger.info("Performing sanity check for environment!")
        QA::Support::Retrier.retry_on_exception do
          QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
        end
      end
    end
  end
end
