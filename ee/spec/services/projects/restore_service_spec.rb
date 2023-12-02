# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RestoreService do
  let(:user) { create(:user) }
  let(:pending_delete) { nil }
  let(:project) do
    create(:project,
      :repository,
      name: 'project 1-deleted-177483',
      namespace: user.namespace,
      marked_for_deletion_at: 1.day.ago,
      deleting_user: user,
      archived: true,
      hidden: true,
      pending_delete: pending_delete)
  end

  context 'restoring project' do
    subject { described_class.new(project, user).execute }

    it 'marks project as not hidden, unarchived and not marked for deletion' do
      subject

      expect(Project.unscoped.all).to include(project)

      expect(project.archived).to eq(false)
      expect(project.hidden).to eq(false)
      expect(project.marked_for_deletion_at).to be_nil
      expect(project.deleting_user).to eq(nil)
    end

    context 'when the original project path is not taken' do
      it 'renames the project back to its original path' do
        expect { subject }.to change { project.path }.from("project_1-deleted-177483").to("project_1")
      end

      it 'renames the project back to its original name' do
        expect { subject }.to change { project.name }.from("project 1-deleted-177483").to("project 1")
      end
    end

    context 'when the original project name has been taken' do
      before do
        create(:project, name: 'project 1', namespace: user.namespace, deleting_user: user)
      end

      it 'renames the project back to its original path with a suffix' do
        expect { subject }.to change { project.path }.from("project_1-deleted-177483").to(/project_1-[a-zA-Z0-9]{5}/)
      end

      it 'renames the project back to its original name with a suffix' do
        expect { subject }.to change { project.name }.from("project 1-deleted-177483").to(/project 1-[a-zA-Z0-9]{5}/)
      end

      it 'uses the same suffix for both the path and name' do
        subject

        path_suffix = project.path.split('-')[-1]
        name_suffix = project.name.split('-')[-1]

        expect(path_suffix).to eq(name_suffix)
      end
    end

    context 'when the original project path does not contain the -deleted- suffix' do
      let(:project) do
        create(:project,
               :repository,
               name: 'a project name',
               namespace: user.namespace,
               marked_for_deletion_at: 1.day.ago,
               deleting_user: user,
               archived: true,
               pending_delete: pending_delete)
      end

      it 'renames the project back to its original path' do
        expect { subject }.not_to change { project.path }
      end

      it 'renames the project back to its original name' do
        expect { subject }.not_to change { project.name }
      end
    end
  end

  context 'restoring project already in process of removal' do
    let(:deletion_date) { 2.days.ago }
    let(:pending_delete) { true }

    it 'does not allow to restore' do
      expect(described_class.new(project, user).execute).to include(status: :error)
    end
  end

  context 'audit events' do
    it 'saves audit event' do
      expect { described_class.new(project, user).execute }
        .to change { AuditEvent.count }.by(3)
    end
  end
end
