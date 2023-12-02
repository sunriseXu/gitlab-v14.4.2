# frozen_string_literal: true
module EE
  module SystemNotes
    module IssuablesService
      extend ::Gitlab::Utils::Override
      # Called when the health_status of an Issue is changed
      #
      # Example Note text:
      #
      #   "removed the health status"
      #
      #   "changed health status to at risk"
      #
      # Returns the created Note object
      def change_health_status_note
        health_status = noteable.health_status&.humanize(capitalize: false)
        body = health_status ? "changed health status to **#{health_status}**" : 'removed the health status'

        if noteable.is_a?(Issue)
          issue_activity_counter.track_issue_health_status_changed_action(author: author, project: project)
        end

        create_note(NoteSummary.new(noteable, project, author, body, action: 'health_status'))
      end

      # Called when the an issue is published to a project's
      # status page application
      #
      # Example Note text:
      #
      #   "published this issue to the status page"
      #
      # Returns the created Note object
      def publish_issue_to_status_page
        body = 'published this issue to the status page'

        create_note(NoteSummary.new(noteable, project, author, body, action: 'published'))
      end

      # Called when an issuable is linked as blocking
      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "marked this issue as blocking gitlab-foss#9001"
      #   "marked this epic as blocking &9"
      #
      # Returns the created Note object
      def block_issuable(noteable_ref)
        body = block_message(noteable_name, noteable_ref.to_reference(noteable.resource_parent), 'blocking')

        track_issue_event(:track_issue_related_action)

        create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
      end

      # Called when an issuable is linked as a blocked by
      #
      # noteable_ref - Referenced noteable object
      #
      # Example Note text:
      #
      #   "marked this issue as blocked by gitlab-foss#9001"
      #   "marked this epic as blocked by &9"
      #
      # Returns the created Note object
      def blocked_by_issuable(noteable_ref)
        body = block_message(noteable_name, noteable_ref.to_reference(noteable.resource_parent), 'blocked by')

        track_issue_event(:track_issue_related_action)

        create_note(NoteSummary.new(noteable, project, author, body, action: 'relate'))
      end

      override :track_cross_reference_action
      def track_cross_reference_action
        super

        return unless noteable.is_a?(Epic)

        counter = ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter

        counter.track_epic_cross_referenced(author: author, namespace: noteable.group)
      end

      private

      def block_message(issuable_type, noteable_reference, type)
        "marked this #{issuable_type} as #{type} #{noteable_reference}"
      end

      def noteable_name
        noteable.to_ability_name.humanize(capitalize: false)
      end
    end
  end
end
