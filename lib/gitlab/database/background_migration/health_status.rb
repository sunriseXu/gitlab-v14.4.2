# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      module HealthStatus
        DEFAULT_INIDICATORS = [
          Indicators::AutovacuumActiveOnTable,
          Indicators::WriteAheadLog
        ].freeze

        # Rather than passing along the migration, we use a more explicitly defined context
        Context = Struct.new(:connection, :tables)

        def self.evaluate(migration, indicators = DEFAULT_INIDICATORS)
          indicators.map do |indicator|
            signal = begin
              indicator.new(migration.health_context).evaluate
            rescue StandardError => e
              Gitlab::ErrorTracking.track_exception(e, migration_id: migration.id,
                                                       job_class_name: migration.job_class_name)

              Signals::Unknown.new(indicator, reason: "unexpected error: #{e.message} (#{e.class})")
            end

            log_signal(signal, migration) if signal.log_info?

            signal
          end
        end

        def self.log_signal(signal, migration)
          Gitlab::AppLogger.info(
            message: "#{migration} signaled: #{signal}",
            migration_id: migration.id
          )
        end
      end
    end
  end
end
