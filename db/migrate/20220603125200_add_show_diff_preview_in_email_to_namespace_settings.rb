# frozen_string_literal: true

class AddShowDiffPreviewInEmailToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :show_diff_preview_in_email, :boolean, default: true, null: false
  end
end
