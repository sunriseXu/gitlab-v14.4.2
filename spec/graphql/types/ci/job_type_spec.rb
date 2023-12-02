# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobType do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('CiJob') }
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Job) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      active
      allow_failure
      artifacts
      cancelable
      commitPath
      coverage
      created_at
      created_by_tag
      detailedStatus
      duration
      downstreamPipeline
      finished_at
      id
      kind
      manual_job
      manual_variables
      name
      needs
      pipeline
      playable
      previousStageJobsOrNeeds
      queued_at
      queued_duration
      refName
      refPath
      retryable
      retried
      scheduledAt
      schedulingType
      shortSha
      stage
      started_at
      status
      stuck
      tags
      triggered
      userPermissions
      webPath
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#web_path' do
    subject { resolve_field(:web_path, build, current_user: user, object_type: described_class) }

    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, project: project, user: user) }

    it 'returns the web path of the job' do
      is_expected.to eq("/#{project.full_path}/-/jobs/#{build.id}")
    end
  end
end
