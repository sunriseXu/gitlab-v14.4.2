# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Renamed < BaseImporter
          def execute(issue_event)
            Note.create!(note_params(issue_event))
          end

          private

          def note_params(issue_event)
            {
              noteable_id: issuable_db_id(issue_event),
              noteable_type: issuable_type(issue_event),
              project_id: project.id,
              author_id: author_id(issue_event),
              note: parse_body(issue_event),
              system: true,
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at,
              system_note_metadata: SystemNoteMetadata.new(
                {
                  action: "title",
                  created_at: issue_event.created_at,
                  updated_at: issue_event.created_at
                }
              )
            }
          end

          def parse_body(issue_event)
            old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(
              issue_event.old_title, issue_event.new_title
            ).inline_diffs

            marked_old_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(issue_event.old_title).mark(old_diffs)
            marked_new_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(issue_event.new_title).mark(new_diffs)

            "changed title from **#{marked_old_title}** to **#{marked_new_title}**"
          end
        end
      end
    end
  end
end
