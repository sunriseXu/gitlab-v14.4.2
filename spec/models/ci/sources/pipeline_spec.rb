# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Sources::Pipeline do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:pipeline) }

  it { is_expected.to belong_to(:source_project).class_name('::Project') }
  it { is_expected.to belong_to(:source_job) }
  it { is_expected.to belong_to(:source_bridge) }
  it { is_expected.to belong_to(:source_pipeline) }

  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:pipeline) }

  it { is_expected.to validate_presence_of(:source_project) }
  it { is_expected.to validate_presence_of(:source_job) }
  it { is_expected.to validate_presence_of(:source_pipeline) }

  context 'loose foreign key on ci_sources_pipelines.source_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_sources_pipeline, source_project: parent) }
    end
  end

  context 'loose foreign key on ci_sources_pipelines.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_sources_pipeline, project: parent) }
    end
  end
end
