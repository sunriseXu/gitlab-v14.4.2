# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtV2 do
  let(:namespace) { build_stubbed(:namespace) }
  let(:project) { build_stubbed(:project, namespace: namespace) }
  let(:user) { build_stubbed(:user) }
  let(:pipeline) { build_stubbed(:ci_pipeline, ref: 'auto-deploy-2020-03-19') }
  let(:build) do
    build_stubbed(
      :ci_build,
      project: project,
      user: user,
      pipeline: pipeline
    )
  end

  subject(:ci_job_jwt_v2) { described_class.new(build, ttl: 30) }

  it { is_expected.to be_a Gitlab::Ci::Jwt }

  describe '#payload' do
    subject(:payload) { ci_job_jwt_v2.payload }

    it 'has correct values for the standard JWT attributes' do
      aggregate_failures do
        expect(payload[:iss]).to eq(Settings.gitlab.base_url)
        expect(payload[:aud]).to eq(Settings.gitlab.base_url)
        expect(payload[:sub]).to eq("project_path:#{project.full_path}:ref_type:branch:ref:#{pipeline.source_ref}")
      end
    end
  end
end
