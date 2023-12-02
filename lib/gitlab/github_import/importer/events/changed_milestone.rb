# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedMilestone < BaseImporter
          # GitHub API doesn't provide the historical state of an issue for
          # de/milestoned issue events. So we'll assign the default state to
          # those events that are imported from GitHub.
          DEFAULT_STATE = Issue.available_states[:opened]

          def execute(issue_event)
            create_event(issue_event)
          end

          private

          def create_event(issue_event)
            attrs = {
              user_id: author_id(issue_event),
              created_at: issue_event.created_at,
              milestone_id: project.milestones.find_by_title(issue_event.milestone_title)&.id,
              action: action(issue_event.event),
              state: DEFAULT_STATE
            }.merge(resource_event_belongs_to(issue_event))

            ResourceMilestoneEvent.create!(attrs)
          end

          def action(event_type)
            return ResourceMilestoneEvent.actions[:remove] if event_type == 'demilestoned'

            ResourceMilestoneEvent.actions[:add]
          end
        end
      end
    end
  end
end
