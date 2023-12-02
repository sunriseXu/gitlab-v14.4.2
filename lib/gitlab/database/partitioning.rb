# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class TableWithoutModel < Gitlab::Database::SharedModel
        include PartitionedTable
      end

      class << self
        def register_models(models)
          models.each do |model|
            raise "#{model} should have partitioning strategy defined" unless model.respond_to?(:partitioning_strategy)

            registered_models << model
          end
        end

        def register_tables(tables)
          registered_tables.merge(tables)
        end

        def sync_partitions_ignore_db_error
          sync_partitions unless ENV['DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP']
        rescue ActiveRecord::ActiveRecordError, PG::Error
          # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
        end

        def sync_partitions(models_to_sync = registered_for_sync, only_on: nil)
          Gitlab::AppLogger.info(message: 'Syncing dynamic postgres partitions')

          Gitlab::Database::EachDatabase.each_model_connection(models_to_sync, only_on: only_on) do |model|
            PartitionManager.new(model).sync_partitions
          end

          unless only_on
            models_to_sync.each do |model|
              next if model < ::Gitlab::Database::SharedModel && !(model < TableWithoutModel)

              Gitlab::Database::EachDatabase.each_database_connection do |connection, connection_name|
                if connection_name != model.connection_db_config.name
                  PartitionManager.new(model, connection: connection).sync_partitions
                end
              end
            end
          end

          Gitlab::AppLogger.info(message: 'Finished sync of dynamic postgres partitions')
        end

        def report_metrics(models_to_monitor = registered_models)
          partition_monitoring = PartitionMonitoring.new

          Gitlab::Database::EachDatabase.each_model_connection(models_to_monitor) do |model|
            partition_monitoring.report_metrics_for_model(model)
          end
        end

        def drop_detached_partitions
          Gitlab::AppLogger.info(message: 'Dropping detached postgres partitions')

          Gitlab::Database::EachDatabase.each_database_connection do
            DetachedPartitionDropper.new.perform
          end

          Gitlab::AppLogger.info(message: 'Finished dropping detached postgres partitions')
        end

        def registered_models
          @registered_models ||= Set.new
        end

        def registered_tables
          @registered_tables ||= Set.new
        end

        private

        def registered_for_sync
          registered_models + registered_tables.map do |table|
            table_without_model(**table)
          end
        end

        def table_without_model(table_name:, partitioned_column:, strategy:, limit_connection_names: nil)
          Class.new(TableWithoutModel).tap do |klass|
            klass.table_name = table_name
            klass.partitioned_by(partitioned_column, strategy: strategy)
            klass.limit_connection_names = limit_connection_names
          end
        end
      end
    end
  end
end
