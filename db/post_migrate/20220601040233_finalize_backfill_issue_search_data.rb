# frozen_string_literal: true

class FinalizeBackfillIssueSearchData < Gitlab::Database::Migration[2.0]
  MIGRATION = 'BackfillIssueSearchData'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :issues,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
