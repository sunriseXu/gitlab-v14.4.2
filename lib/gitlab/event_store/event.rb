# frozen_string_literal: true

# An Event object represents a domain event that occurred in a bounded context.
# By publishing events we notify other bounded contexts about something
# that happened, so that they can react to it.
#
# Define new event classes under `app/events/<namespace>/` with a name
# representing something that happened in the past:
#
#   class Projects::ProjectCreatedEvent < Gitlab::EventStore::Event
#     def schema
#       {
#         'type' => 'object',
#         'properties' => {
#           'project_id' => { 'type' => 'integer' }
#         }
#       }
#     end
#   end
#
# To publish it:
#
#   Gitlab::EventStore.publish(
#     Projects::ProjectCreatedEvent.new(data: { project_id: project.id })
#   )
#
module Gitlab
  module EventStore
    class Event
      attr_reader :data

      def initialize(data:)
        validate_schema!(data)
        @data = data
      end

      def schema
        raise NotImplementedError, 'must specify schema to validate the event'
      end

      private

      def validate_schema!(data)
        unless data.is_a?(Hash)
          raise Gitlab::EventStore::InvalidEvent, "Event data must be a Hash"
        end

        unless JSONSchemer.schema(schema).valid?(data.deep_stringify_keys)
          raise Gitlab::EventStore::InvalidEvent, "Data for event #{self.class} does not match the defined schema: #{schema}"
        end
      end
    end
  end
end
