# frozen_string_literal: true

class Admin::BackgroundMigrationsController < Admin::ApplicationController
  feature_category :database
  urgency :low

  around_action :support_multiple_databases

  def index
    @relations_by_tab = {
      'queued' => batched_migration_class.queued.queue_order,
      'failed' => batched_migration_class.with_status(:failed).queue_order,
      'finished' => batched_migration_class.with_status(:finished).queue_order.reverse_order
    }

    @current_tab = @relations_by_tab.key?(params[:tab]) ? params[:tab] : 'queued'
    @migrations = @relations_by_tab[@current_tab].page(params[:page])
    @successful_rows_counts = batched_migration_class.successful_rows_counts(@migrations.map(&:id))
    @databases = Gitlab::Database.db_config_names
  end

  def show
    @migration = batched_migration_class.find(params[:id])

    @failed_jobs = @migration.batched_jobs.with_status(:failed).page(params[:page])
  end

  def pause
    migration = batched_migration_class.find(params[:id])
    migration.pause!

    redirect_back fallback_location: { action: 'index' }
  end

  def resume
    migration = batched_migration_class.find(params[:id])
    migration.execute!

    redirect_back fallback_location: { action: 'index' }
  end

  def retry
    migration = batched_migration_class.find(params[:id])
    migration.retry_failed_jobs! if migration.failed?

    redirect_back fallback_location: { action: 'index' }
  end

  private

  def support_multiple_databases
    Gitlab::Database::SharedModel.using_connection(base_model.connection) do
      yield
    end
  end

  def base_model
    @selected_database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME

    Gitlab::Database.database_base_models[@selected_database]
  end

  def batched_migration_class
    @batched_migration_class ||= Gitlab::Database::BackgroundMigration::BatchedMigration
  end
end
