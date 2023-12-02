# frozen_string_literal: true

module Ci
  class AfterRequeueJobService < ::BaseService
    def execute(processable)
      @processable = processable

      process_subsequent_jobs
      reset_source_bridge
    end

    private

    def process_subsequent_jobs
      dependent_jobs.each do |job|
        process(job)
      end
    end

    def reset_source_bridge
      @processable.pipeline.reset_source_bridge!(current_user)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def dependent_jobs
      return legacy_dependent_jobs unless ::Feature.enabled?(:ci_requeue_with_dag_object_hierarchy, project)

      ordered_by_dag(
        ::Ci::Processable
          .from_union(needs_dependent_jobs, stage_dependent_jobs)
          .skipped
          .ordered_by_stage
          .preload(:needs)
      )
    end

    def process(job)
      Gitlab::OptimisticLocking.retry_lock(job, name: 'ci_requeue_job') do |job|
        job.process(current_user)
      end
    end

    def stage_dependent_jobs
      @processable.pipeline.processables.after_stage(@processable.stage_idx)
    end

    def needs_dependent_jobs
      ::Gitlab::Ci::ProcessableObjectHierarchy.new(
        ::Ci::Processable.where(id: @processable.id)
      ).descendants
    end

    def legacy_skipped_jobs
      @legacy_skipped_jobs ||= @processable.pipeline.processables.skipped
    end

    def legacy_dependent_jobs
      ordered_by_dag(
        legacy_stage_dependent_jobs.or(legacy_needs_dependent_jobs).ordered_by_stage.preload(:needs)
      )
    end

    def legacy_stage_dependent_jobs
      legacy_skipped_jobs.after_stage(@processable.stage_idx)
    end

    def legacy_needs_dependent_jobs
      legacy_skipped_jobs.scheduling_type_dag.with_needs([@processable.name])
    end

    def ordered_by_dag(jobs)
      sorted_job_names = sort_jobs(jobs).each_with_index.to_h

      jobs.group_by(&:stage_idx).flat_map do |_, stage_jobs|
        stage_jobs.sort_by { |job| sorted_job_names.fetch(job.name) }
      end
    end

    def sort_jobs(jobs)
      Gitlab::Ci::YamlProcessor::Dag.order(
        jobs.to_h do |job|
          [job.name, job.needs.map(&:name)]
        end
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
