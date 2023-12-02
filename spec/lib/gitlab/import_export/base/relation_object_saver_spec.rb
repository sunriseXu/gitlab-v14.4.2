# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Base::RelationObjectSaver do
  let(:project) { create(:project) }
  let(:relation_object) { build(:issue, project: project) }
  let(:relation_definition) { {} }
  let(:importable) { project }
  let(:relation_key) { 'issues' }

  subject(:saver) do
    described_class.new(
      relation_object: relation_object,
      relation_key: relation_key,
      relation_definition: relation_definition,
      importable: importable
    )
  end

  describe '#save' do
    before do
      expect(relation_object).to receive(:save!).and_call_original
    end

    it 'saves relation object' do
      expect { saver.execute }.to change(project.issues, :count).by(1)
    end

    context 'when subrelation is present' do
      let(:notes) { build_list(:note, 6, project: project, importing: true) }
      let(:relation_object) { build(:issue, project: project, notes: notes) }
      let(:relation_definition) { { 'notes' => {} } }

      it 'saves relation object with subrelations' do
        expect(relation_object.notes).to receive(:<<).and_call_original

        saver.execute

        issue = project.issues.last
        expect(issue.notes.count).to eq(6)
      end
    end

    context 'when subrelation is not a collection' do
      let(:sentry_issue) { build(:sentry_issue, importing: true) }
      let(:relation_object) { build(:issue, project: project, sentry_issue: sentry_issue) }
      let(:relation_definition) { { 'sentry_issue' => {} } }

      it 'saves subrelation as part of the relation object itself' do
        expect(relation_object.notes).not_to receive(:<<)

        saver.execute

        issue = project.issues.last
        expect(issue.sentry_issue.persisted?).to eq(true)
      end
    end

    context 'when subrelation collection count is small' do
      let(:note) { build(:note, project: project, importing: true) }
      let(:relation_object) { build(:issue, project: project, notes: [note]) }
      let(:relation_definition) { { 'notes' => {} } }

      it 'saves subrelation as part of the relation object itself' do
        expect(relation_object.notes).not_to receive(:<<)

        saver.execute

        issue = project.issues.last
        expect(issue.notes.count).to eq(1)
      end
    end

    context 'when some subrelations are invalid' do
      let(:notes) { build_list(:note, 5, project: project, importing: true) }
      let(:invalid_note) { build(:note) }
      let(:relation_object) { build(:issue, project: project, notes: notes + [invalid_note]) }
      let(:relation_definition) { { 'notes' => {} } }

      it 'saves valid subrelations and logs invalid subrelation' do
        expect(relation_object.notes).to receive(:<<).twice.and_call_original
        expect(Gitlab::Import::Logger)
          .to receive(:info)
          .with(
            message: '[Project/Group Import] Invalid subrelation',
            project_id: project.id,
            relation_key: 'issues',
            error_messages: "Project does not match noteable project"
          )

        saver.execute

        issue = project.issues.last
        import_failure = project.import_failures.last

        expect(invalid_note.persisted?).to eq(false)
        expect(issue.notes.count).to eq(5)
        expect(import_failure.source).to eq('RelationObjectSaver#save!')
        expect(import_failure.exception_message).to eq('Project does not match noteable project')
      end

      context 'when invalid subrelation can still be persisted' do
        let(:relation_key) { 'merge_requests' }
        let(:relation_definition) { { 'approvals' => {} } }
        let(:approval_1) { build(:approval, merge_request_id: nil, user: create(:user)) }
        let(:approval_2) { build(:approval, merge_request_id: nil, user: create(:user)) }
        let(:relation_object) { build(:merge_request, source_project: project, target_project: project, approvals: [approval_1, approval_2]) }

        it 'saves the subrelation' do
          expect(approval_1.valid?).to eq(false)
          expect(Gitlab::Import::Logger).not_to receive(:info)

          saver.execute

          expect(project.merge_requests.first.approvals.count).to eq(2)
          expect(project.merge_requests.first.approvals.first.persisted?).to eq(true)
        end
      end

      context 'when importable is group' do
        let(:relation_key) { 'labels' }
        let(:relation_definition) { { 'priorities' => {} } }
        let(:importable) { create(:group) }
        let(:valid_priorities) { build_list(:label_priority, 5, importing: true) }
        let(:invalid_priority) { build(:label_priority, priority: -1) }
        let(:relation_object) { build(:group_label, group: importable, title: 'test', priorities: valid_priorities + [invalid_priority]) }

        it 'logs invalid subrelation for a group' do
          expect(Gitlab::Import::Logger)
            .to receive(:info)
            .with(
              message: '[Project/Group Import] Invalid subrelation',
              group_id: importable.id,
              relation_key: 'labels',
              error_messages: 'Priority must be greater than or equal to 0'
            )

          saver.execute

          label = importable.labels.last
          import_failure = importable.import_failures.last

          expect(label.priorities.count).to eq(5)
          expect(import_failure.source).to eq('RelationObjectSaver#save!')
          expect(import_failure.exception_message).to eq('Priority must be greater than or equal to 0')
        end
      end
    end
  end
end
