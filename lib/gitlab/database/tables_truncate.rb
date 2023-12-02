# frozen_string_literal: true

module Gitlab
  module Database
    class TablesTruncate
      GITLAB_SCHEMAS_TO_IGNORE = %i[gitlab_geo].freeze

      def initialize(database_name:, min_batch_size:, logger: nil, until_table: nil, dry_run: false)
        @database_name = database_name
        @min_batch_size = min_batch_size
        @logger = logger
        @until_table = until_table
        @dry_run = dry_run
      end

      def execute
        raise "Cannot truncate legacy tables in single-db setup" unless Gitlab::Database.has_config?(:ci)
        raise "database is not supported" unless %w[main ci].include?(database_name)

        logger&.info "DRY RUN:" if dry_run

        connection = Gitlab::Database.database_base_models[database_name].connection

        schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)
        tables_to_truncate = Gitlab::Database::GitlabSchema.tables_to_schema.reject do |_, schema_name|
          (GITLAB_SCHEMAS_TO_IGNORE.union(schemas_for_connection)).include?(schema_name)
        end.keys

        tables_sorted = Gitlab::Database::TablesSortedByForeignKeys.new(connection, tables_to_truncate).execute
        # Checking if all the tables have the write-lock triggers
        # to make sure we are deleting the right tables on the right database.
        tables_sorted.flatten.each do |table_name|
          query = <<~SQL
            SELECT COUNT(*) from information_schema.triggers
            WHERE event_object_table = '#{table_name}'
            AND trigger_name = 'gitlab_schema_write_trigger_for_#{table_name}'
          SQL

          if connection.select_value(query) == 0
            raise "Table '#{table_name}' is not locked for writes. Run the rake task gitlab:db:lock_writes first"
          end
        end

        if until_table
          table_index = tables_sorted.find_index { |tables_group| tables_group.include?(until_table) }
          raise "The table '#{until_table}' is not within the truncated tables" if table_index.nil?

          tables_sorted = tables_sorted[0..table_index]
        end

        # min_batch_size is the minimum number of new tables to truncate at each stage.
        # But in each stage we have also have to truncate the already truncated tables in the previous stages
        logger&.info "Truncating legacy tables for the database #{database_name}"
        truncate_tables_in_batches(connection, tables_sorted, min_batch_size)
      end

      private

      attr_accessor :database_name, :min_batch_size, :logger, :dry_run, :until_table

      def truncate_tables_in_batches(connection, tables_sorted, min_batch_size)
        truncated_tables = []

        tables_sorted.flatten.each do |table|
          sql_statement = "SELECT set_config('lock_writes.#{table}', 'false', false)"
          logger&.info(sql_statement)
          connection.execute(sql_statement) unless dry_run
        end

        # We do the truncation in stages to avoid high IO
        # In each stage, we truncate the new tables along with the already truncated
        # tables before. That's because PostgreSQL doesn't allow to truncate any table (A)
        # without truncating any other table (B) that has a Foreign Key pointing to the table (A).
        # even if table (B) is empty, because it has been already truncated in a previous stage.
        tables_sorted.in_groups_of(min_batch_size, false).each do |tables_groups|
          new_tables_to_truncate = tables_groups.flatten
          logger&.info "= New tables to truncate: #{new_tables_to_truncate.join(', ')}"
          truncated_tables.push(*new_tables_to_truncate).tap(&:sort!)
          sql_statements = [
            "SET LOCAL statement_timeout = 0",
            "SET LOCAL lock_timeout = 0",
            "TRUNCATE TABLE #{truncated_tables.join(', ')} RESTRICT"
          ]

          sql_statements.each { |sql_statement| logger&.info(sql_statement) }

          next if dry_run

          connection.transaction do
            sql_statements.each { |sql_statement| connection.execute(sql_statement) }
          end
        end
      end
    end
  end
end
