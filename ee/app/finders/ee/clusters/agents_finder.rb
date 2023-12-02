# frozen_string_literal: true

module EE
  # Clusters::AgentsFinder
  #
  # Extends Clusters::AgentsFinder
  #
  # Added arguments:
  #   params:
  #     has_vulnerabilities: boolean
  #
  module Clusters
    module AgentsFinder
      extend ::Gitlab::Utils::Override

      private

      override :filter_clusters
      def filter_clusters(agents)
        agents = super(agents)
        agents = agents.has_vulnerabilities(params[:has_vulnerabilities]) unless params[:has_vulnerabilities].nil?

        agents
      end
    end
  end
end
