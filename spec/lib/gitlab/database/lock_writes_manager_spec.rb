# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockWritesManager do
  let(:connection) { ApplicationRecord.connection }
  let(:test_table) { '_test_table' }
  let(:logger) { instance_double(Logger) }
  let(:dry_run) { false }

  subject(:lock_writes_manager) do
    described_class.new(
      table_name: test_table,
      connection: connection,
      database_name: 'main',
      logger: logger,
      dry_run: dry_run
    )
  end

  before do
    allow(logger).to receive(:info)

    connection.execute(<<~SQL)
      CREATE TABLE #{test_table} (id integer NOT NULL, value integer NOT NULL DEFAULT 0);

      INSERT INTO #{test_table} (id, value)
      VALUES (1, 1), (2, 2), (3, 3)
    SQL
  end

  describe "#table_locked_for_writes?" do
    it 'returns false for a table that is not locked for writes' do
      expect(subject.table_locked_for_writes?(test_table)).to eq(false)
    end

    it 'returns true for a table that is locked for writes' do
      expect { subject.lock_writes }.to change { subject.table_locked_for_writes?(test_table) }.from(false).to(true)
    end
  end

  describe '#lock_writes' do
    it 'prevents any writes on the table' do
      subject.lock_writes

      expect do
        connection.execute("delete from #{test_table}")
      end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{test_table}" is write protected/)
    end

    it 'prevents truncating the table' do
      subject.lock_writes

      expect do
        connection.execute("truncate #{test_table}")
      end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{test_table}" is write protected/)
    end

    it 'adds 3 triggers to the ci schema tables on the main database' do
      expect do
        subject.lock_writes
      end.to change {
        number_of_triggers_on(connection, test_table)
      }.by(3) # Triggers to block INSERT / UPDATE / DELETE
      # Triggers on TRUNCATE are not added to the information_schema.triggers
      # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
    end

    it 'logs the write locking' do
      expect(logger).to receive(:info).with("Database: 'main', Table: '_test_table': Lock Writes")

      subject.lock_writes
    end

    it 'retries again if it receives a statement_timeout a few number of times' do
      error_message = "PG::QueryCanceled: ERROR: canceling statement due to statement timeout"
      call_count = 0
      allow(connection).to receive(:execute) do |statement|
        if statement.include?("CREATE TRIGGER")
          call_count += 1
          raise(ActiveRecord::QueryCanceled, error_message) if call_count.even?
        end
      end
      subject.lock_writes
    end

    it 'raises the exception if it happened many times' do
      error_message = "PG::QueryCanceled: ERROR: canceling statement due to statement timeout"
      allow(connection).to receive(:execute) do |statement|
        if statement.include?("CREATE TRIGGER")
          raise(ActiveRecord::QueryCanceled, error_message)
        end
      end

      expect do
        subject.lock_writes
      end.to raise_error(ActiveRecord::QueryCanceled)
    end

    it 'skips the operation if the table is already locked for writes' do
      subject.lock_writes

      expect(logger).to receive(:info).with("Skipping lock_writes, because #{test_table} is already locked for writes")
      expect(connection).not_to receive(:execute).with(/CREATE TRIGGER/)

      expect do
        subject.lock_writes
      end.not_to change {
        number_of_triggers_on(connection, test_table)
      }
    end

    context 'when running in dry_run mode' do
      let(:dry_run) { true }

      it 'prints the sql statement to the logger' do
        expect(logger).to receive(:info).with("Database: 'main', Table: '#{test_table}': Lock Writes")
        expected_sql_statement = <<~SQL
          CREATE TRIGGER gitlab_schema_write_trigger_for_#{test_table}
            BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE
            ON #{test_table}
            FOR EACH STATEMENT EXECUTE FUNCTION gitlab_schema_prevent_write();
        SQL
        expect(logger).to receive(:info).with(expected_sql_statement)

        subject.lock_writes
      end

      it 'does not lock the tables for writes' do
        subject.lock_writes

        expect do
          connection.execute("delete from #{test_table}")
          connection.execute("truncate #{test_table}")
        end.not_to raise_error
      end
    end
  end

  describe '#unlock_writes' do
    before do
      # Locking the table without the considering the value of dry_run
      described_class.new(
        table_name: test_table,
        connection: connection,
        database_name: 'main',
        logger: logger,
        dry_run: false
      ).lock_writes
    end

    it 'allows writing on the table again' do
      subject.unlock_writes

      expect do
        connection.execute("delete from #{test_table}")
      end.not_to raise_error
    end

    it 'removes the write protection triggers from the gitlab_main tables on the ci database' do
      expect do
        subject.unlock_writes
      end.to change {
        number_of_triggers_on(connection, test_table)
      }.by(-3) # Triggers to block INSERT / UPDATE / DELETE
      # Triggers on TRUNCATE are not added to the information_schema.triggers
      # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
    end

    it 'logs the write unlocking' do
      expect(logger).to receive(:info).with("Database: 'main', Table: '_test_table': Allow Writes")

      subject.unlock_writes
    end

    context 'when running in dry_run mode' do
      let(:dry_run) { true }

      it 'prints the sql statement to the logger' do
        expect(logger).to receive(:info).with("Database: 'main', Table: '#{test_table}': Allow Writes")
        expected_sql_statement = <<~SQL
          DROP TRIGGER IF EXISTS gitlab_schema_write_trigger_for_#{test_table} ON #{test_table};
        SQL
        expect(logger).to receive(:info).with(expected_sql_statement)

        subject.unlock_writes
      end

      it 'does not unlock the tables for writes' do
        subject.unlock_writes

        expect do
          connection.execute("delete from #{test_table}")
        end.to raise_error(ActiveRecord::StatementInvalid, /Table: "#{test_table}" is write protected/)
      end
    end
  end

  def number_of_triggers_on(connection, table_name)
    connection
      .select_value("SELECT count(*) FROM information_schema.triggers WHERE event_object_table=$1", nil, [table_name])
  end
end
