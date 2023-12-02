# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::AssignPartition do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:step) { described_class.new(pipeline, command) }
  let(:current_partition_id) { 123 }

  describe '#perform!' do
    before do
      allow(Ci::Pipeline).to receive(:current_partition_value) { current_partition_id }
    end

    subject { step.perform! }

    it 'assigns partition_id to pipeline' do
      expect { subject }.to change(pipeline, :partition_id).to(current_partition_id)
    end

    context 'with parent-child pipelines' do
      let(:bridge) do
        instance_double(Ci::Bridge,
          triggers_child_pipeline?: true,
          parent_pipeline: instance_double(Ci::Pipeline, partition_id: 125))
      end

      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: project,
          current_user: user,
          bridge: bridge)
      end

      it 'assigns partition_id to pipeline' do
        expect { subject }.to change(pipeline, :partition_id).to(125)
      end
    end
  end
end
