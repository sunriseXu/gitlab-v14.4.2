# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection, query_analyzers: false do
  let(:analyzer) { described_class }

  # We keep only the GitlabSchemasValidateConnection analyzer running
  around do |example|
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed(false) do
      example.run
    end
  end

  context 'properly observes all queries', :request_store do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "for simple query observes schema correctly" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects",
          expect_error: nil,
          setup: nil
        },
        "for query accessing gitlab_ci and gitlab_main" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects LEFT JOIN ci_builds ON ci_builds.project_id=projects.id",
          expect_error: /The query tried to access \["projects", "ci_builds"\]/,
          setup: -> (_) { skip_if_multiple_databases_not_setup }
        },
        "for query accessing gitlab_ci and gitlab_main the gitlab_schemas is always ordered" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds LEFT JOIN projects ON ci_builds.project_id=projects.id",
          expect_error: /The query tried to access \["ci_builds", "projects"\]/,
          setup: -> (_) { skip_if_multiple_databases_not_setup }
        },
        "for query accessing main table from CI database" => {
          model: Ci::ApplicationRecord,
          sql: "SELECT 1 FROM projects",
          expect_error: /The query tried to access \["projects"\]/,
          setup: -> (_) { skip_if_multiple_databases_not_setup }
        },
        "for query accessing CI database" => {
          model: Ci::ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds",
          expect_error: nil
        },
        "for query accessing CI table from main database" => {
          model: ::ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds",
          expect_error: /The query tried to access \["ci_builds"\]/,
          setup: -> (_) { skip_if_multiple_databases_not_setup }
        }
      }
    end

    with_them do
      it do
        instance_eval(&setup) if setup

        if expect_error
          expect { process_sql(model, sql) }.to raise_error(expect_error)
        else
          expect { process_sql(model, sql) }.not_to raise_error
        end
      end
    end
  end

  context "when analyzer is enabled for tests", :query_analyzers do
    before do
      skip_if_multiple_databases_not_setup
    end

    it "throws an error when trying to access a table that belongs to the gitlab_main schema from the ci database" do
      expect do
        Ci::ApplicationRecord.connection.execute("select * from users limit 1")
      end.to raise_error(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection::CrossSchemaAccessError)
    end

    it "throws an error when trying to access a table that belongs to the gitlab_ci schema from the main database" do
      expect do
        ApplicationRecord.connection.execute("select * from ci_builds limit 1")
      end.to raise_error(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection::CrossSchemaAccessError)
    end
  end

  def process_sql(model, sql)
    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) do
      # Skip load balancer and retrieve connection assigned to model
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, model.retrieve_connection)
    end
  end
end
