# frozen_string_literal: true

module IncidentManagement
  class EscalationPoliciesFinder
    def initialize(current_user, project, params = {})
      @current_user = current_user
      @project = project
      @params = params
    end

    def execute
      return IncidentManagement::EscalationPolicy.none unless allowed?

      collection = project.incident_management_escalation_policies
      collection = by_name_search(collection)
      by_id(collection)
    end

    private

    attr_reader :current_user, :project, :params

    def allowed?
      Ability.allowed?(current_user, :read_incident_management_escalation_policy, project)
    end

    def by_id(collection)
      return collection unless params[:id]

      collection.id_in(params[:id])
    end

    def by_name_search(collection)
      return collection unless params[:name_search].present?

      collection.search_by_name(params[:name_search])
    end
  end
end
