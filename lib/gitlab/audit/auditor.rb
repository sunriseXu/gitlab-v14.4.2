# frozen_string_literal: true

module Gitlab
  module Audit
    class Auditor
      attr_reader :scope, :name

      # Record audit events
      #
      # @param [Hash] context
      # @option context [String] :name the operation name to be audited, used for error tracking
      # @option context [User] :author the user who authors the change
      # @option context [User, Project, Group] :scope the scope which audit event belongs to
      # @option context [Object] :target the target object being audited
      # @option context [String] :message the message describing the action
      # @option context [Hash] :additional_details the additional details we want to merge into audit event details.
      # @option context [Time] :created_at the time that the event occurred (defaults to the current time)
      #
      # @example Using block (useful when events are emitted deep in the call stack)
      #   i.e. multiple audit events
      #
      #   audit_context = {
      #     name: 'merge_approval_rule_updated',
      #     author: current_user,
      #     scope: project_alpha,
      #     target: merge_approval_rule,
      #     message: 'a user has attempted to update an approval rule'
      #   }
      #
      #   # in the initiating service
      #   Gitlab::Audit::Auditor.audit(audit_context) do
      #     service.execute
      #   end
      #
      #   # in the model
      #   Auditable.push_audit_event('an approver has been added')
      #   Auditable.push_audit_event('an approval group has been removed')
      #
      # @example Using standard method call
      #   i.e. single audit event
      #
      #   merge_approval_rule.save
      #   Gitlab::Audit::Auditor.audit(audit_context)
      #
      # @return result of block execution
      def self.audit(context, &block)
        auditor = new(context)

        return unless auditor.audit_enabled?

        if block
          auditor.multiple_audit(&block)
        else
          auditor.single_audit
        end
      end

      def initialize(context = {})
        @context = context

        @name = @context.fetch(:name, 'audit_operation')
        @stream_only = @context.fetch(:stream_only, false)
        @author = @context.fetch(:author)
        @scope = @context.fetch(:scope)
        @target = @context.fetch(:target)
        @created_at = @context.fetch(:created_at, DateTime.current)
        @message = @context.fetch(:message, '')
        @additional_details = @context.fetch(:additional_details, {})
        @ip_address = @context[:ip_address]
        @target_details = @context[:target_details]
        @authentication_event = @context.fetch(:authentication_event, false)
        @authentication_provider = @context[:authentication_provider]
      end

      def single_audit
        events = [build_event(@message)]

        record(events)
      end

      def multiple_audit
        # For now we dont have any need to implement multiple audit event functionality in CE
        # Defined in EE
      end

      def record(events)
        log_events(events) unless @stream_only
        send_to_stream(events)
      end

      def log_events(events)
        log_authentication_event
        log_to_database(events)
        log_to_file(events)
      end

      def audit_enabled?
        authentication_event?
      end

      def authentication_event?
        @authentication_event
      end

      def log_authentication_event
        return unless Gitlab::Database.read_write? && authentication_event?

        event = AuthenticationEvent.new(authentication_event_payload)
        event.save!
      rescue ActiveRecord::RecordInvalid => e
        ::Gitlab::ErrorTracking.track_exception(e, audit_operation: @name)
      end

      def authentication_event_payload
        {
          # @author can be a User or various Gitlab::Audit authors.
          # Only capture real users for successful authentication events.
          user: author_if_user,
          user_name: @author.name,
          ip_address: Gitlab::RequestContext.instance.client_ip || @author.current_sign_in_ip,
          result: AuthenticationEvent.results[:success],
          provider: @authentication_provider
        }
      end

      def author_if_user
        @author if @author.is_a?(User)
      end

      def send_to_stream(events)
        # Defined in EE
      end

      def build_event(message)
        AuditEvents::BuildService.new(
          author: @author,
          scope: @scope,
          target: @target,
          created_at: @created_at,
          message: message,
          additional_details: @additional_details,
          ip_address: @ip_address,
          target_details: @target_details
        ).execute
      end

      def log_to_database(events)
        AuditEvent.bulk_insert!(events)
      rescue ActiveRecord::RecordInvalid => e
        ::Gitlab::ErrorTracking.track_exception(e, audit_operation: @name)
      end

      def log_to_file(events)
        file_logger = ::Gitlab::AuditJsonLogger.build

        events.each { |event| file_logger.info(log_payload(event)) }
      end

      private

      def log_payload(event)
        payload = event.as_json
        details = formatted_details(event.details)
        payload["details"] = details
        payload.merge!(details).as_json
      end

      def formatted_details(details)
        details.merge(details.slice(:from, :to).transform_values(&:to_s))
      end
    end
  end
end

Gitlab::Audit::Auditor.prepend_mod_with("Gitlab::Audit::Auditor")
