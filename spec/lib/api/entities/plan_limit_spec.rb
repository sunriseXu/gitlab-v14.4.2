# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PlanLimit do
  let(:plan_limits) { create(:plan_limits) }

  subject { described_class.new(plan_limits).as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :ci_pipeline_size,
      :ci_active_jobs,
      :ci_active_pipelines,
      :ci_project_subscriptions,
      :ci_pipeline_schedules,
      :ci_needs_size_limit,
      :ci_registered_group_runners,
      :ci_registered_project_runners,
      :conan_max_file_size,
      :generic_packages_max_file_size,
      :helm_max_file_size,
      :maven_max_file_size,
      :npm_max_file_size,
      :nuget_max_file_size,
      :pypi_max_file_size,
      :terraform_module_max_file_size,
      :storage_size_limit
    )
  end

  it 'does not expose id and plan_id' do
    expect(subject).not_to include(:id, :plan_id)
  end
end
