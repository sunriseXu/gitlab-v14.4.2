# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesTruncate, :reestablished_active_record_base,
               :suppress_gitlab_schemas_validate_connection do
  include MigrationsHelpers

  let(:logger) { instance_double(Logger) }
  let(:dry_run) { false }
  let(:until_table) { nil }
  let(:min_batch_size) { 1 }
  let(:main_connection) { ApplicationRecord.connection }
  let(:ci_connection) { Ci::ApplicationRecord.connection }
  let(:test_gitlab_main_table) { '_test_gitlab_main_table' }
  let(:test_gitlab_ci_table) { '_test_gitlab_ci_table' }

  # Main Database
  let(:main_db_main_item_model) { table("_test_gitlab_main_items", database: "main") }
  let(:main_db_main_reference_model) { table("_test_gitlab_main_references", database: "main") }
  let(:main_db_ci_item_model) { table("_test_gitlab_ci_items", database: "main") }
  let(:main_db_ci_reference_model) { table("_test_gitlab_ci_references", database: "main") }
  let(:main_db_shared_item_model) { table("_test_gitlab_shared_items", database: "main") }
  # CI Database
  let(:ci_db_main_item_model) { table("_test_gitlab_main_items", database: "ci") }
  let(:ci_db_main_reference_model) { table("_test_gitlab_main_references", database: "ci") }
  let(:ci_db_ci_item_model) { table("_test_gitlab_ci_items", database: "ci") }
  let(:ci_db_ci_reference_model) { table("_test_gitlab_ci_references", database: "ci") }
  let(:ci_db_shared_item_model) { table("_test_gitlab_shared_items", database: "ci") }

  subject(:truncate_legacy_tables) do
    described_class.new(
      database_name: database_name,
      min_batch_size: min_batch_size,
      logger: logger,
      dry_run: dry_run,
      until_table: until_table
    ).execute
  end

  shared_examples 'truncating legacy tables on a database' do
    before do
      skip_if_multiple_databases_not_setup

      # Creating some test tables on the main database
      main_tables_sql = <<~SQL
        CREATE TABLE _test_gitlab_main_items (id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_gitlab_main_references (
          id serial NOT NULL PRIMARY KEY,
          item_id BIGINT NOT NULL,
          CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
        );
      SQL

      main_connection.execute(main_tables_sql)
      ci_connection.execute(main_tables_sql)

      ci_tables_sql = <<~SQL
        CREATE TABLE _test_gitlab_ci_items (id serial NOT NULL PRIMARY KEY);

        CREATE TABLE _test_gitlab_ci_references (
          id serial NOT NULL PRIMARY KEY,
          item_id BIGINT NOT NULL,
          CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_ci_items(id)
        );
      SQL

      main_connection.execute(ci_tables_sql)
      ci_connection.execute(ci_tables_sql)

      internal_tables_sql = <<~SQL
        CREATE TABLE _test_gitlab_shared_items (id serial NOT NULL PRIMARY KEY);
      SQL

      main_connection.execute(internal_tables_sql)
      ci_connection.execute(internal_tables_sql)

      # Filling the tables
      5.times do |i|
        # Main Database
        main_db_main_item_model.create!(id: i)
        main_db_main_reference_model.create!(item_id: i)
        main_db_ci_item_model.create!(id: i)
        main_db_ci_reference_model.create!(item_id: i)
        main_db_shared_item_model.create!(id: i)
        # CI Database
        ci_db_main_item_model.create!(id: i)
        ci_db_main_reference_model.create!(item_id: i)
        ci_db_ci_item_model.create!(id: i)
        ci_db_ci_reference_model.create!(item_id: i)
        ci_db_shared_item_model.create!(id: i)
      end

      allow(Gitlab::Database::GitlabSchema).to receive(:tables_to_schema).and_return(
        {
          "_test_gitlab_main_items" => :gitlab_main,
          "_test_gitlab_main_references" => :gitlab_main,
          "_test_gitlab_ci_items" => :gitlab_ci,
          "_test_gitlab_ci_references" => :gitlab_ci,
          "_test_gitlab_shared_items" => :gitlab_shared,
          "_test_gitlab_geo_items" => :gitlab_geo
        }
      )

      allow(logger).to receive(:info).with(any_args)
    end

    context 'when the truncated tables are not locked for writes' do
      it 'raises an error that the tables are not locked for writes' do
        error_message = /is not locked for writes. Run the rake task gitlab:db:lock_writes first/
        expect { truncate_legacy_tables }.to raise_error(error_message)
      end
    end

    context 'when the truncated tables are locked for writes' do
      before do
        legacy_tables_models.map(&:table_name).each do |table|
          Gitlab::Database::LockWritesManager.new(
            table_name: table,
            connection: connection,
            database_name: database_name
          ).lock_writes
        end
      end

      it 'truncates the legacy tables' do
        old_counts = legacy_tables_models.map(&:count)
        expect do
          truncate_legacy_tables
        end.to change { legacy_tables_models.map(&:count) }.from(old_counts).to([0] * legacy_tables_models.length)
      end

      it 'does not affect the other tables' do
        expect do
          truncate_legacy_tables
        end.not_to change { other_tables_models.map(&:count) }
      end

      it 'logs the sql statements to the logger' do
        expect(logger).to receive(:info).with("SET LOCAL lock_timeout = 0")
        expect(logger).to receive(:info).with("SET LOCAL statement_timeout = 0")
        expect(logger).to receive(:info)
                      .with(/TRUNCATE TABLE #{legacy_tables_models.map(&:table_name).sort.join(', ')} RESTRICT/)
        truncate_legacy_tables
      end

      context 'when running in dry_run mode' do
        let(:dry_run) { true }

        it 'does not truncate the legacy tables if running in dry run mode' do
          legacy_tables_models = [main_db_ci_reference_model, main_db_ci_reference_model]
          expect do
            truncate_legacy_tables
          end.not_to change { legacy_tables_models.map(&:count) }
        end
      end

      context 'when passing until_table parameter' do
        context 'with a table that exists' do
          let(:until_table) { referencing_table_model.table_name }

          it 'only truncates until the table specified' do
            expect do
              truncate_legacy_tables
            end.to change(referencing_table_model, :count).by(-5)
               .and change(referenced_table_model, :count).by(0)
          end
        end

        context 'with a table that does not exist' do
          let(:until_table) { 'foobar' }

          it 'raises an error if the specified table does not exist' do
            expect do
              truncate_legacy_tables
            end.to raise_error(/The table 'foobar' is not within the truncated tables/)
          end
        end
      end

      context 'with geo configured' do
        let(:geo_connection) { Gitlab::Database.database_base_models[:geo].connection }

        before do
          skip unless geo_configured?
          geo_connection.execute('CREATE TABLE _test_gitlab_geo_items (id serial NOT NULL PRIMARY KEY)')
          geo_connection.execute('INSERT INTO _test_gitlab_geo_items VALUES(generate_series(1, 50))')
        end

        it 'does not truncate gitlab_geo tables' do
          expect do
            truncate_legacy_tables
          end.not_to change { geo_connection.select_value("select count(*) from _test_gitlab_geo_items") }
        end
      end
    end
  end

  context 'when truncating gitlab_ci tables on the main database' do
    let(:connection) { ApplicationRecord.connection }
    let(:database_name) { "main" }
    let(:legacy_tables_models) { [main_db_ci_item_model, main_db_ci_reference_model] }
    let(:referencing_table_model) { main_db_ci_reference_model }
    let(:referenced_table_model) { main_db_ci_item_model }
    let(:other_tables_models) do
      [
        main_db_main_item_model, main_db_main_reference_model,
        ci_db_ci_item_model, ci_db_ci_reference_model,
        ci_db_main_item_model, ci_db_main_reference_model,
        main_db_shared_item_model, ci_db_shared_item_model
      ]
    end

    it_behaves_like 'truncating legacy tables on a database'
  end

  context 'when truncating gitlab_main tables on the ci database' do
    let(:connection) { Ci::ApplicationRecord.connection }
    let(:database_name) { "ci" }
    let(:legacy_tables_models) { [ci_db_main_item_model, ci_db_main_reference_model] }
    let(:referencing_table_model) { ci_db_main_reference_model }
    let(:referenced_table_model) { ci_db_main_item_model }
    let(:other_tables_models) do
      [
        main_db_main_item_model, main_db_main_reference_model,
        ci_db_ci_item_model, ci_db_ci_reference_model,
        main_db_ci_item_model, main_db_ci_reference_model,
        main_db_shared_item_model, ci_db_shared_item_model
      ]
    end

    it_behaves_like 'truncating legacy tables on a database'
  end

  context 'when running in a single database mode' do
    before do
      skip_if_multiple_databases_are_setup
    end

    it 'raises an error when truncating the main database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'main', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end

    it 'raises an error when truncating the ci database that it is a single database setup' do
      expect do
        described_class.new(database_name: 'ci', min_batch_size: min_batch_size).execute
      end.to raise_error(/Cannot truncate legacy tables in single-db setup/)
    end
  end

  def geo_configured?
    !!ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'geo')
  end
end
