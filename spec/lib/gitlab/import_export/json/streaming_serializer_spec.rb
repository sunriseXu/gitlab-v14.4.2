# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Json::StreamingSerializer do
  let_it_be(:user) { create(:user) }
  let_it_be(:release) { create(:release) }
  let_it_be(:group) { create(:group) }

  let_it_be(:exportable) do
    create(:project,
      :public,
      :repository,
      :issues_disabled,
      :wiki_enabled,
      :builds_private,
      description: 'description',
      releases: [release],
      group: group,
      approvals_before_merge: 1)
  end

  let_it_be(:issue) do
    create(:issue,
      assignees: [user],
      project: exportable)
  end

  let(:exportable_path) { 'project' }
  let(:logger) { Gitlab::Export::Logger.build }
  let(:json_writer) { instance_double('Gitlab::ImportExport::Json::LegacyWriter') }
  let(:hash) { { name: exportable.name, description: exportable.description }.stringify_keys }
  let(:include) { [] }
  let(:custom_orderer) { nil }
  let(:include_if_exportable) { {} }

  let(:relations_schema) do
    {
      only: [:name, :description],
      include: include,
      preload: { issues: nil },
      export_reorder: custom_orderer,
      include_if_exportable: include_if_exportable
    }
  end

  subject do
    described_class.new(exportable, relations_schema, json_writer, exportable_path: exportable_path, logger: logger, current_user: user)
  end

  describe '#execute' do
    before do
      allow(json_writer).to receive(:write_attributes).with(exportable_path, hash)
    end

    it 'calls json_writer.write_attributes with proper params' do
      subject.execute
    end

    context 'with many relations' do
      let(:include) do
        [{ issues: { include: [] } }]
      end

      before do
        create_list(:issue, 3, project: exportable, relative_position: 10000) # ascending ids, same position positive
        create_list(:issue, 3, project: exportable, relative_position: -5000) # ascending ids, same position negative
        create_list(:issue, 3, project: exportable, relative_position: 0) # ascending ids, duplicate positions
        create_list(:issue, 3, project: exportable, relative_position: nil) # no position
        create_list(:issue, 3, :with_desc_relative_position, project: exportable ) # ascending ids, descending position
      end

      it 'calls json_writer.write_relation_array with proper params' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(issue.to_json))

        subject.execute
      end

      it 'logs the relation name and the number of records to export' do
        allow(json_writer).to receive(:write_relation_array)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: "Exporting issues relation. Number of records to export: 16",
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end

      context 'default relation ordering' do
        it 'orders exported issues by primary key(:id)' do
          expected_issues = exportable.issues.reorder(:id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering ascending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :asc,
              nulls_position: :nulls_last
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.reorder(:relative_position, :id).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end

      context 'custom relation ordering descending' do
        let(:custom_orderer) do
          {
            issues: {
              column: :relative_position,
              direction: :desc,
              nulls_position: :nulls_first
            }
          }
        end

        it 'orders exported issues by custom column(relative_position)' do
          expected_issues = exportable.issues.reorder(Issue.arel_table[:relative_position].desc.nulls_first).order(id: :desc).map(&:to_json)

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, expected_issues)

          subject.execute
        end
      end
    end

    context 'with single relation' do
      let(:group_options) do
        { include: [], only: [:name, :path, :description] }
      end

      let(:include) do
        [{ group: group_options }]
      end

      it 'calls json_writer.write_relation with proper params' do
        expect(json_writer).to receive(:write_relation).with(exportable_path, :group, group.to_json(group_options))

        subject.execute
      end

      it 'logs the relation name' do
        allow(json_writer).to receive(:write_relation)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: 'Exporting group relation',
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end
    end

    context 'with array relation' do
      let(:project_member) { create(:project_member, user: user) }
      let(:include) do
        [{ project_members: { include: [] } }]
      end

      before do
        allow(exportable).to receive(:project_members).and_return([project_member])
      end

      it 'calls json_writer.write_relation_array with proper params' do
        expect(json_writer).to receive(:write_relation_array).with(exportable_path, :project_members, array_including(project_member.to_json))

        subject.execute
      end

      it 'logs the relation name and the number of records to export' do
        allow(json_writer).to receive(:write_relation_array)
        allow(logger).to receive(:info)

        subject.execute

        expect(logger).to have_received(:info).with(
          importer: 'Import/Export',
          message: 'Exporting project_members relation. Number of records to export: 1',
          project_id: exportable.id,
          project_name: exportable.name,
          project_path: exportable.full_path
        )
      end
    end

    describe 'load balancing' do
      it 'reads from replica' do
        expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries).and_call_original

        subject.execute
      end
    end

    describe 'conditional export of included associations' do
      let(:include) do
        [{ issues: { include: [{ label_links: { include: [:label] } }] } }]
      end

      let(:include_if_exportable) do
        { issues: [:label_links] }
      end

      let_it_be(:label) { create(:label, project: exportable) }
      let_it_be(:link) { create(:label_link, label: label, target: issue) }

      context 'when association is exportable' do
        before do
          allow_next_found_instance_of(Issue) do |issue|
            allow(issue).to receive(:exportable_association?).with(:label_links, current_user: user).and_return(true)
          end
        end

        it 'includes exportable association' do
          expected_issue = issue.to_json(include: [{ label_links: { include: [:label] } }])

          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(expected_issue))

          subject.execute
        end
      end

      context 'when association is not exportable' do
        before do
          allow_next_found_instance_of(Issue) do |issue|
            allow(issue).to receive(:exportable_association?).with(:label_links, current_user: user).and_return(false)
          end
        end

        it 'filters out not exportable association' do
          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(issue.to_json))

          subject.execute
        end
      end

      context 'when association does not respond to exportable_association?' do
        before do
          allow_next_found_instance_of(Issue) do |issue|
            allow(issue).to receive(:respond_to?).with(:exportable_association?).and_return(false)
          end
        end

        it 'filters out not exportable association' do
          expect(json_writer).to receive(:write_relation_array).with(exportable_path, :issues, array_including(issue.to_json))

          subject.execute
        end
      end
    end
  end

  describe '#serialize_relation' do
    context 'when record is a merge request' do
      let(:json_writer) do
        Class.new do
          def write_relation_array(_, _, enumerator)
            enumerator.each { _1 }
          end
        end.new
      end

      it 'removes cached external diff' do
        merge_request = create(:merge_request, source_project: exportable, target_project: exportable)
        cache_dir = merge_request.merge_request_diff.send(:external_diff_cache_dir)

        expect(subject).to receive(:remove_cached_external_diff).with(merge_request).twice

        subject.serialize_relation({ merge_requests: { include: [] } })

        expect(Dir.exist?(cache_dir)).to eq(false)
      end
    end
  end
end
