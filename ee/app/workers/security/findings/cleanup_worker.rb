# frozen_string_literal: true

module Security
  module Findings
    class CleanupWorker
      include ApplicationWorker
      include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

      feature_category :vulnerability_management
      data_consistency :always

      idempotent!

      def perform
        return unless Feature.enabled?(:purge_stale_security_findings, type: :ops)

        ::Security::Findings::CleanupService.delete_stale_records
      end
    end
  end
end
