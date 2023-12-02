# frozen_string_literal: true

module Users
  class MigrateRecordsToGhostUserInBatchesWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :users
    data_consistency :always
    idempotent!

    def perform
      return unless Feature.enabled?(:user_destroy_with_limited_execution_time_worker)

      in_lock(self.class.name.underscore, ttl: Gitlab::Utils::ExecutionTracker::MAX_RUNTIME, retries: 0) do
        Users::MigrateRecordsToGhostUserInBatchesService.new.execute
      end
    end
  end
end
