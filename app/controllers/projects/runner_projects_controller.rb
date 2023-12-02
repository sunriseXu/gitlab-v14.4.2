# frozen_string_literal: true

class Projects::RunnerProjectsController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  feature_category :runner
  urgency :low

  def create
    @runner = Ci::Runner.find(params[:runner_project][:runner_id])

    return head(403) unless can?(current_user, :assign_runner, @runner)

    path = project_runners_path(project)

    if ::Ci::Runners::AssignRunnerService.new(@runner, @project, current_user).execute.success?
      redirect_to path, notice: s_('Runners|Runner assigned to project.')
    else
      assign_to_messages = @runner.errors.messages[:assign_to]
      alert = assign_to_messages&.join(',') || 'Failed adding runner to project'

      redirect_to path, alert: alert
    end
  end

  def destroy
    runner_project = project.runner_projects.find(params[:id])

    ::Ci::Runners::UnassignRunnerService.new(runner_project, current_user).execute

    redirect_to project_runners_path(project), status: :found, notice: s_('Runners|Runner unassigned from project.')
  end
end
