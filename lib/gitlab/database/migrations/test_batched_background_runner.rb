# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBatchedBackgroundRunner < BaseBackgroundRunner
        include Gitlab::Database::DynamicModelHelpers
        attr_reader :connection

        def initialize(result_dir:, connection:)
          super(result_dir: result_dir)
          @connection = connection
        end

        def jobs_by_migration_name
          Gitlab::Database::BackgroundMigration::BatchedMigration
            .executable
            .created_after(3.hours.ago) # Simple way to exclude migrations already running before migration testing
            .to_h do |migration|
            batching_strategy = migration.batch_class.new(connection: connection)

            smallest_batch_start = migration.next_min_value

            table_max_value = define_batchable_model(migration.table_name, connection: connection)
                                .maximum(migration.column_name)

            largest_batch_start = table_max_value - migration.batch_size

            # variance is the portion of the batch range that we shrink between variance * 0 and variance * 1
            # to pick actual batches to sample.
            variance = largest_batch_start - smallest_batch_start

            batch_starts = uniform_fractions
                             .lazy # frac varies from 0 to 1, values in smallest_batch_start..largest_batch_start
                             .map { |frac| (variance * frac).to_i + smallest_batch_start }

            # Track previously run batches so that we stop sampling if a new batch would intersect an older one
            completed_batches = []

            jobs_to_sample = batch_starts
                               # Stop sampling if a batch would intersect a previous batch
                               .take_while { |start| completed_batches.none? { |batch| batch.cover?(start) } }
                               .map do |batch_start|
              next_bounds = batching_strategy.next_batch(
                migration.table_name,
                migration.column_name,
                batch_min_value: batch_start,
                batch_size: migration.batch_size,
                job_arguments: migration.job_arguments
              )

              batch_min, batch_max = next_bounds

              job = migration.create_batched_job!(batch_min, batch_max)

              completed_batches << (batch_min..batch_max)

              job
            end

            [migration.job_class_name, jobs_to_sample]
          end
        end

        def run_job(job)
          Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection).perform(job)
        end

        def uniform_fractions
          Enumerator.new do |y|
            # Generates equally distributed fractions between 0 and 1, with increasing detail as more are pulled from
            # the enumerator.
            # 0, 1 (special case)
            # 1/2
            # 1/4, 3/4
            # 1/8, 3/8, 5/8, 7/8
            # etc.
            # The pattern here is at each outer loop, the denominator multiplies by 2, and at each inner loop,
            # the numerator counts up all odd numbers 1 <= n < denominator.
            y << 0
            y << 1

            # denominators are each increasing power of 2
            denominators = (1..).lazy.map { |exponent| 2**exponent }

            denominators.each do |denominator|
              # Numerators at the current step are all odd numbers between 1 and the denominator
              numerators = (1..denominator).step(2)

              numerators.each do |numerator|
                next_frac = numerator.fdiv(denominator)
                y << next_frac
              end
            end
          end
        end
      end
    end
  end
end
