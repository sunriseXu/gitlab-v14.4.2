# frozen_string_literal: true

class ChangeTaskSystemNoteWordingToChecklistItem < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  MIGRATION = 'RenameTaskSystemNoteToChecklistItem'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  MAX_BATCH_SIZE = 20_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :system_note_metadata,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :system_note_metadata, :id, [])
  end
end
