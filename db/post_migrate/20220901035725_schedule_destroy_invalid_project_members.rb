# frozen_string_literal: true

class ScheduleDestroyInvalidProjectMembers < Gitlab::Database::Migration[2.0]
  MIGRATION = 'DestroyInvalidProjectMembers'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000
  MAX_BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 200

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :members,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      gitlab_schema: :gitlab_main
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :members, :id, [])
  end
end
