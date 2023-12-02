# frozen_string_literal: true

module Ci
  class CancelPipelineWorker
    include ApplicationWorker

    # lots of updates to ci_builds
    data_consistency :always
    feature_category :continuous_integration
    idempotent!
    deduplicate :until_executed
    urgency :high

    def perform(pipeline_id, auto_canceled_by_pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        pipeline.cancel_running(
          # cascade_to_children is false because we iterate through children
          # we also cancel bridges prior to prevent more children
          cascade_to_children: false,
          auto_canceled_by_pipeline_id: auto_canceled_by_pipeline_id
        )
      end
    end
  end
end
