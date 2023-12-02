# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # The purpose of this analyzer is to validate if tables observed
      # are properly used according to schema used by current connection
      class GitlabSchemasValidateConnection < Base
        CrossSchemaAccessError = Class.new(QueryAnalyzerError)

        class << self
          def enabled?
            true
          end

          def analyze(parsed)
            tables = parsed.pg.select_tables + parsed.pg.dml_tables
            table_schemas = ::Gitlab::Database::GitlabSchema.table_schemas(tables)
            return if table_schemas.empty?

            allowed_schemas = ::Gitlab::Database.gitlab_schemas_for_connection(parsed.connection)
            return unless allowed_schemas

            invalid_schemas = table_schemas - allowed_schemas
            if invalid_schemas.any?
              message = "The query tried to access #{tables} (of #{table_schemas.to_a}) "
              message += "which is outside of allowed schemas (#{allowed_schemas}) "
              message += "for the current connection '#{Gitlab::Database.db_config_name(parsed.connection)}'"

              raise CrossSchemaAccessError, message
            end
          end
        end
      end
    end
  end
end
