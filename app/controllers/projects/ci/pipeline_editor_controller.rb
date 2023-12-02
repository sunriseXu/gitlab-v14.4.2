# frozen_string_literal: true

class Projects::Ci::PipelineEditorController < Projects::ApplicationController
  before_action :check_can_collaborate!
  before_action do
    push_frontend_feature_flag(:schema_linting, @project)
  end

  feature_category :pipeline_authoring

  urgency :low, [:show]

  def show
  end

  private

  def check_can_collaborate!
    render_404 unless can_collaborate_with_project?(@project)
  end
end
