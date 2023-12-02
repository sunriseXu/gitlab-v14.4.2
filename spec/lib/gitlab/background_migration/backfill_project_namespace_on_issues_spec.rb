# frozen_string_literal: true

require 'spec_helper'
# todo: this will need to specify schema version once we introduce the not null constraint on issues#namespace_id
# https://gitlab.com/gitlab-org/gitlab/-/issues/367835
RSpec.describe Gitlab::BackgroundMigration::BackfillProjectNamespaceOnIssues do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }

  let(:namespace1) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let(:namespace2) { namespaces.create!(name: 'batchtest2', type: 'Group', parent_id: namespace1.id, path: 'space2') }

  let(:proj_namespace1) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace1.id) }
  let(:proj_namespace2) { namespaces.create!(name: 'proj2', path: 'proj2', type: 'Project', parent_id: namespace2.id) }

  # rubocop:disable Layout/LineLength
  let(:proj1) { projects.create!(name: 'proj1', path: 'proj1', namespace_id: namespace1.id, project_namespace_id: proj_namespace1.id) }
  let(:proj2) { projects.create!(name: 'proj2', path: 'proj2', namespace_id: namespace2.id, project_namespace_id: proj_namespace2.id) }

  let!(:proj1_issue_with_namespace) { issues.create!(title: 'issue1', project_id: proj1.id, namespace_id: proj_namespace1.id) }
  let!(:proj1_issue_without_namespace1) { issues.create!(title: 'issue2', project_id: proj1.id) }
  let!(:proj1_issue_without_namespace2) { issues.create!(title: 'issue3', project_id: proj1.id) }
  let!(:proj2_issue_with_namespace) { issues.create!(title: 'issue4', project_id: proj2.id, namespace_id: proj_namespace2.id) }
  let!(:proj2_issue_without_namespace1) { issues.create!(title: 'issue5', project_id: proj2.id) }
  let!(:proj2_issue_without_namespace2) { issues.create!(title: 'issue6', project_id: proj2.id) }
  # rubocop:enable Layout/LineLength

  let(:migration) do
    described_class.new(
      start_id: proj1_issue_with_namespace.id,
      end_id: proj2_issue_without_namespace2.id,
      batch_table: :issues,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) { migration.perform }

  it 'backfills namespace_id for the selected records', :aggregate_failures do
    perform_migration

    expected_namespaces = [proj_namespace1.id, proj_namespace2.id]

    expect(issues.where.not(namespace_id: nil).count).to eq(6)
    expect(issues.where.not(namespace_id: nil).pluck(:namespace_id).uniq).to match_array(expected_namespaces)
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
