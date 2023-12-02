# frozen_string_literal: true

module API
  module Entities
    class ProjectIntegration < Entities::ProjectIntegrationBasic
      # Expose serialized properties
      expose :properties do |integration, options|
        integration.api_field_names.to_h do |name|
          [name, integration.public_send(name)] # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
