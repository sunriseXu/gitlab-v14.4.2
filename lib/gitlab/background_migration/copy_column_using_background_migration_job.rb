# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration that updates the value of one or more
    # columns using the value of other columns in the same table.
    #
    # - The {start_id, end_id} arguments are at the start so that it can be used
    #   with `queue_batched_background_migration`
    # - Uses sub-batching so that we can keep each update's execution time at
    #   low 100s ms, while being able to update more records per 2 minutes
    #   that we allow background migration jobs to be scheduled one after the other
    # - We skip the NULL checks as they may result in not using an index scan
    # - The table that is migrated does _not_ need `id` as the primary key
    #   We use the provided primary_key column to perform the update.
    class CopyColumnUsingBackgroundMigrationJob < BatchedMigrationJob
      job_arguments :copy_from, :copy_to

      def perform
        assignment_clauses = build_assignment_clauses(copy_from, copy_to)

        each_sub_batch(operation_name: :update_all) do |relation|
          relation.update_all(assignment_clauses)
        end
      end

      private

      def build_assignment_clauses(copy_from, copy_to)
        copy_from = Array.wrap(copy_from)
        copy_to = Array.wrap(copy_to)

        unless copy_from.count == copy_to.count
          raise ArgumentError, 'number of source and destination columns must match'
        end

        assignments = copy_from.zip(copy_to).map do |from_column, to_column|
          from_column = connection.quote_column_name(from_column)
          to_column = connection.quote_column_name(to_column)

          "#{to_column} = #{from_column}"
        end

        assignments.join(', ')
      end
    end
  end
end
