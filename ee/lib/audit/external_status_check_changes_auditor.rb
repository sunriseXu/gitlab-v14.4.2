# frozen_string_literal: true

module Audit
  class ExternalStatusCheckChangesAuditor < ::EE::Audit::BaseChangesAuditor
    def initialize(current_user, external_status_check)
      @project = external_status_check.project

      super
    end

    def execute
      audit_changes(:name, as: 'name', entity: @project, model: model)
      audit_changes(:external_url, as: 'external url', entity: @project, model: model)
    end

    def attributes_from_auditable_model(column)
      {
        from: model.previous_changes[column].first,
        to: model.previous_changes[column].last
      }
    end
  end
end
