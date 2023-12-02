# frozen_string_literal: true

module Gitlab
  module Metrics
    module GlobalSearchSlis
      class << self
        # The following targets are the 99.95th percentile of code searches
        # gathered on 24-08-2022
        # from https://log.gprd.gitlab.net/goto/0c89cd80-23af-11ed-8656-f5f2137823ba (internal only)
        BASIC_CONTENT_TARGET_S = 7.031
        BASIC_CODE_TARGET_S = 21.903
        ADVANCED_CONTENT_TARGET_S = 4.865
        ADVANCED_CODE_TARGET_S = 13.546

        def initialize_slis!
          if Feature.enabled?(:global_search_custom_slis)
            Gitlab::Metrics::Sli::Apdex.initialize_sli(:global_search, possible_labels)
          end

          return unless Feature.enabled?(:global_search_error_rate_sli)

          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(:global_search, possible_labels)
        end

        def record_apdex(elapsed:, search_type:, search_level:, search_scope:)
          return unless Feature.enabled?(:global_search_custom_slis)

          Gitlab::Metrics::Sli::Apdex[:global_search].increment(
            labels: labels(search_type: search_type, search_level: search_level, search_scope: search_scope),
            success: elapsed < duration_target(search_type, search_scope)
          )
        end

        def record_error_rate(error:, search_type:, search_level:, search_scope:)
          return unless Feature.enabled?(:global_search_error_rate_sli)

          Gitlab::Metrics::Sli::ErrorRate[:global_search].increment(
            labels: labels(search_type: search_type, search_level: search_level, search_scope: search_scope),
            error: error
          )
        end

        private

        def duration_target(search_type, search_scope)
          if search_type == 'basic' && content_search?(search_scope)
            BASIC_CONTENT_TARGET_S
          elsif search_type == 'basic' && code_search?(search_scope)
            BASIC_CODE_TARGET_S
          elsif search_type == 'advanced' && content_search?(search_scope)
            ADVANCED_CONTENT_TARGET_S
          elsif search_type == 'advanced' && code_search?(search_scope)
            ADVANCED_CODE_TARGET_S
          end
        end

        def search_types
          %w[basic advanced]
        end

        def search_levels
          %w[project group global]
        end

        def search_scopes
          Gitlab::Search::AbuseDetection::ALLOWED_SCOPES
        end

        def endpoint_ids
          ['SearchController#show', 'GET /api/:version/search', 'GET /api/:version/projects/:id/(-/)search',
           'GET /api/:version/groups/:id/(-/)search']
        end

        def possible_labels
          search_types.flat_map do |search_type|
            search_levels.flat_map do |search_level|
              search_scopes.flat_map do |search_scope|
                endpoint_ids.flat_map do |endpoint_id|
                  {
                    search_type: search_type,
                    search_level: search_level,
                    search_scope: search_scope,
                    endpoint_id: endpoint_id
                  }
                end
              end
            end
          end
        end

        def labels(search_type:, search_level:, search_scope:)
          {
            search_type: search_type,
            search_level: search_level,
            search_scope: search_scope,
            endpoint_id: endpoint_id
          }
        end

        def endpoint_id
          ::Gitlab::ApplicationContext.current_context_attribute(:caller_id)
        end

        def code_search?(search_scope)
          search_scope == 'blobs'
        end

        def content_search?(search_scope)
          !code_search?(search_scope)
        end
      end
    end
  end
end
