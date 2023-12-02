# frozen_string_literal: true

module Types
  module Projects
    class ServiceTypeEnum < BaseEnum
      graphql_name 'ServiceType'

      class << self
        private

        def type_description(name, type)
          "#{type} type"
        end
      end

      # This prepend must stay here because the dynamic block below depends on it.
      prepend_mod # rubocop: disable Cop/InjectEnterpriseEditionModule

      ::Integration.available_integration_names(include_dev: false).each do |name|
        type = "#{name.camelize}Service"
        domain_value = Integration.integration_name_to_type(name)
        value type.underscore.upcase, value: domain_value, description: type_description(name, type)
      end
    end
  end
end
