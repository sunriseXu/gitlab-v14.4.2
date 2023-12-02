# frozen_string_literal: true

module EE
  module Types
    module QueryType
      extend ActiveSupport::Concern
      prepended do
        field :iteration, ::Types::IterationType,
              null: true,
              description: 'Find an iteration.' do
          argument :id, ::Types::GlobalIDType[::Iteration],
                   required: true,
                   description: 'Find an iteration by its ID.'
        end

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              extras: [:lookahead],
              description: "Vulnerabilities reported on projects on the current user's instance security dashboard.",
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability,
              ::Types::VulnerabilityType,
              null: true,
              description: "Find a vulnerability." do
          argument :id, ::Types::GlobalIDType[::Vulnerability],
                   required: true,
                   description: 'Global ID of the Vulnerability.'
        end

        field :vulnerabilities_count_by_day,
              ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver,
              description: 'The historical number of vulnerabilities per day for the projects on the current ' \
                           'user\'s instance security dashboard.'

        field :geo_node, ::Types::Geo::GeoNodeType,
              null: true,
              resolver: ::Resolvers::Geo::GeoNodeResolver,
              description: 'Find a Geo node.'

        field :instance_security_dashboard, ::Types::InstanceSecurityDashboardType,
              null: true,
              resolver: ::Resolvers::InstanceSecurityDashboardResolver,
              description: 'Fields related to Instance Security Dashboard.'

        field :devops_adoption_enabled_namespaces,
              ::Types::Analytics::DevopsAdoption::EnabledNamespaceType.connection_type,
              null: true,
              description: 'Get configured DevOps adoption namespaces. **BETA** This endpoint is subject to change ' \
                           'without notice.',
              resolver: ::Resolvers::Analytics::DevopsAdoption::EnabledNamespacesResolver

        field :current_license, ::Types::Admin::CloudLicenses::CurrentLicenseType,
              null: true,
              resolver: ::Resolvers::Admin::CloudLicenses::CurrentLicenseResolver,
              description: 'Fields related to the current license.'

        field :license_history_entries, ::Types::Admin::CloudLicenses::LicenseHistoryEntryType.connection_type,
              null: true,
              resolver: ::Resolvers::Admin::CloudLicenses::LicenseHistoryEntriesResolver,
              description: 'Fields related to entries in the license history.'

        field :subscription_future_entries, ::Types::Admin::CloudLicenses::SubscriptionFutureEntryType.connection_type,
              null: true,
              resolver: ::Resolvers::Admin::CloudLicenses::SubscriptionFutureEntriesResolver,
              description: 'Fields related to entries in future subscriptions.'

        field :ci_minutes_usage, ::Types::Ci::Minutes::NamespaceMonthlyUsageType.connection_type,
              null: true,
              description: 'CI/CD minutes usage data for a namespace.' do
                argument :namespace_id, ::Types::GlobalIDType[::Namespace],
                  required: false,
                  description: 'Global ID of the Namespace for the monthly CI/CD minutes usage.'
              end

        field :epic_board_list, ::Types::Boards::EpicListType,
               null: true,
               resolver: ::Resolvers::Boards::EpicListResolver
      end

      def vulnerability(id:)
        ::GitlabSchema.find_by_gid(id)
      end

      def iteration(id:)
        ::GitlabSchema.find_by_gid(id)
      end

      def ci_minutes_usage(namespace_id: nil)
        root_namespace = find_root_namespace(namespace_id)
        ::Ci::Minutes::NamespaceMonthlyUsage.for_namespace(root_namespace)
      end

      private

      def find_root_namespace(namespace_id)
        return current_user&.namespace unless namespace_id

        namespace = ::Gitlab::Graphql::Lazy.force(::GitlabSchema.find_by_gid(namespace_id))
        return unless namespace&.root?

        namespace
      end
    end
  end
end
