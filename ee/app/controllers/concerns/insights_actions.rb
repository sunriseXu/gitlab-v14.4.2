# frozen_string_literal: true

module InsightsActions
  extend ActiveSupport::Concern

  included do
    before_action :check_insights_available!
    before_action :validate_params, only: [:query]

    rescue_from Gitlab::Insights::Validators::ParamsValidator::ParamsValidatorError,
      Gitlab::Insights::Finders::IssuableFinder::IssuableFinderError,
      Gitlab::Insights::Executors::DoraExecutor::DoraExecutorError,
      Gitlab::Insights::Reducers::BaseReducer::BaseReducerError, with: :render_insights_chart_error
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: config_data
      end
    end
  end

  def query
    respond_to do |format|
      format.json do
        render json: ::Gitlab::Insights::Loader.new(
          insights_entity: insights_entity,
          current_user: current_user,
          params: params
        ).execute
      end
    end
  end

  private

  def check_insights_available!
    render_404 unless insights_entity.insights_available?
  end

  def validate_params
    Gitlab::Insights::Validators::ParamsValidator.new(params).validate!
  end

  def config_data
    insights_entity.insights_config
  end

  def render_insights_chart_error(exception)
    render json: { message: exception.message }, status: :unprocessable_entity
  end
end
