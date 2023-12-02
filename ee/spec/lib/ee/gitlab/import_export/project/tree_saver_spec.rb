# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::TreeSaver do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:note2) { create(:note, noteable: issue, project: project, author: user) }

  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic_issue) { create(:epic_issue, issue: issue, epic: epic) }

  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec_ee" }

  let_it_be(:push_rule) { create(:push_rule, project: project, max_file_size: 10) }

  shared_examples 'EE saves project tree successfully' do |ndjson_enabled|
    include ::ImportExport::CommonUtil

    let(:full_path) do
      if ndjson_enabled
        File.join(shared.export_path, 'tree')
      else
        File.join(shared.export_path, Gitlab::ImportExport.project_filename)
      end
    end

    let(:shared) { project.import_export_shared }
    let(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }
    let(:issue_json) { get_json(full_path, exportable_path, :issues, ndjson_enabled).first }
    let(:exportable_path) { 'project' }
    let(:epics_available) { true }

    before do
      stub_all_feature_flags
      stub_feature_flags(project_export_as_ndjson: ndjson_enabled)
      stub_licensed_features(epics: epics_available)
      project.add_maintainer(user)
    end

    after do
      FileUtils.rm_rf(export_path)
      FileUtils.rm_rf(full_path)
    end

    context 'epics' do
      it 'contains issue epic object', :aggregate_failures do
        expect(project_tree_saver.save).to be true
        expect(issue_json['epic_issue']).not_to be_empty
        expect(issue_json['epic_issue']['id']).to eql(epic_issue.id)
        expect(issue_json['epic_issue']['epic']['title']).to eql(epic.title)
        expect(issue_json['epic_issue']['epic_id']).to be_nil
        expect(issue_json['epic_issue']['issue_id']).to be_nil
      end

      context 'when epic is not readable' do
        let(:epics_available) { false }

        it 'filters out inaccessible epic object' do
          expect(project_tree_saver.save).to be true
          expect(issue_json['epic_issue']).to be_nil
        end
      end
    end

    context 'security setting' do
      let(:security_json) do
        json = get_json(full_path, exportable_path, :security_setting, ndjson_enabled)
        ndjson_enabled ? json.first : json
      end

      it 'has security settings' do
        expect(project_tree_saver.save).to be true
        expect(security_json['auto_fix_dependency_scanning']).to be_truthy
      end
    end

    context 'push_rule' do
      let(:push_rule_json) do
        json = get_json(full_path, exportable_path, :push_rule, ndjson_enabled)
        ndjson_enabled ? json.first : json
      end

      it 'has push rules' do
        expect(project_tree_saver.save).to be true
        expect(push_rule_json['max_file_size']).to eq(10)
        expect(push_rule_json['force_push_regex']).to eq('feature\/.*')
      end
    end
  end

  context 'with JSON' do
    it_behaves_like "EE saves project tree successfully", false
  end

  context 'with NDJSON' do
    it_behaves_like "EE saves project tree successfully", true
  end
end
