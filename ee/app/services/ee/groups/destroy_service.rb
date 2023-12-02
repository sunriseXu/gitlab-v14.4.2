# frozen_string_literal: true

module EE
  module Groups
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        with_scheduling_epic_cache_update do
          group = super
          after_destroy(group)

          group
        end
      end

      private

      def after_destroy(group)
        delete_dependency_proxy_blobs(group)

        return if group&.persisted?

        log_audit_event

        return unless ::Gitlab::Geo.primary? && group.group_wiki_repository

        group.group_wiki_repository.replicator.handle_after_destroy
      end

      # rubocop:disable Scalability/BulkPerformWithContext
      def with_scheduling_epic_cache_update
        return yield unless ::Feature.enabled?(:cache_issue_sums)

        ids = group.parent_epic_ids_in_ancestor_groups

        group = yield

        ::Epics::UpdateCachedMetadataWorker.bulk_perform_in(
          1.minute,
          ids.each_slice(::Epics::UpdateCachedMetadataWorker::BATCH_SIZE).map { |ids| [ids] }
        )

        group
      end
      # rubocop:enable Scalability/BulkPerformWithContext

      def delete_dependency_proxy_blobs(group)
        # the blobs reference files that need to be destroyed that cascade delete
        # does not remove
        group.dependency_proxy_blobs.destroy_all # rubocop:disable Cop/DestroyAll
      end

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :destroy
        ).for_group.security_event
      end
    end
  end
end
