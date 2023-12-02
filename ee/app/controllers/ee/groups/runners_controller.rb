# frozen_string_literal: true

module EE
  module Groups
    module RunnersController
      extend ActiveSupport::Concern

      prepended do
        before_action do
          push_licensed_feature(:runner_upgrade_management_for_namespace, group)
        end
      end
    end
  end
end
