# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | Install prevent write triggers on all databases"
    task lock_writes: [:environment, 'gitlab:db:validate_config'] do
      Gitlab::Database::EachDatabase.each_database_connection(include_shared: false) do |connection, database_name|
        schemas_for_connection = Gitlab::Database.gitlab_schemas_for_connection(connection)
        Gitlab::Database::GitlabSchema.tables_to_schema.each do |table_name, schema_name|
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
          next if schema_name == :gitlab_geo

          lock_writes_manager = Gitlab::Database::LockWritesManager.new(
            table_name: table_name,
            connection: connection,
            database_name: database_name,
            logger: Logger.new($stdout)
          )

          if schemas_for_connection.include?(schema_name.to_sym)
            lock_writes_manager.unlock_writes
          else
            lock_writes_manager.lock_writes
          end
        end
      end
    end

    desc "GitLab | DB | Remove all triggers that prevents writes from all databases"
    task unlock_writes: :environment do
      Gitlab::Database::EachDatabase.each_database_connection do |connection, database_name|
        Gitlab::Database::GitlabSchema.tables_to_schema.each do |table_name, schema_name|
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/366834
          next if schema_name == :gitlab_geo

          lock_writes_manager = Gitlab::Database::LockWritesManager.new(
            table_name: table_name,
            connection: connection,
            database_name: database_name,
            logger: Logger.new($stdout)
          )

          lock_writes_manager.unlock_writes
        end
      end
    end
  end
end
