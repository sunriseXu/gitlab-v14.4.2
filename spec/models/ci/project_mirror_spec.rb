# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProjectMirror do
  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }

  let!(:project) { create(:project, namespace: group2) }

  context 'scopes' do
    let_it_be(:another_project) { create(:project, namespace: group1) }

    describe '.by_project_id' do
      subject(:result) { described_class.by_project_id(project.id) }

      it 'returns project mirrors of project' do
        expect(result.pluck(:project_id)).to contain_exactly(project.id)
      end
    end

    describe '.by_namespace_id' do
      subject(:result) { described_class.by_namespace_id(group2.id) }

      it 'returns project mirrors of namespace id' do
        expect(result).to contain_exactly(project.ci_project_mirror)
      end
    end
  end

  describe '.sync!' do
    let!(:event) { Projects::SyncEvent.create!(project: project) }

    subject(:sync) { described_class.sync!(event) }

    context 'when project mirror does not exist in the first place' do
      before do
        project.ci_project_mirror.destroy!
      end

      it 'creates a ci_projects record' do
        expect { sync }.to change { described_class.count }.from(0).to(1)

        expect(project.ci_project_mirror).to have_attributes(namespace_id: group2.id)
      end
    end

    context 'when project mirror does already exist' do
      it 'updates the related ci_projects record' do
        expect { sync }.not_to change { described_class.count }

        expect(project.ci_project_mirror).to have_attributes(namespace_id: group2.id)
      end
    end
  end
end
