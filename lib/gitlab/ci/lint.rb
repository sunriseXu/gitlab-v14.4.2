# frozen_string_literal: true

module Gitlab
  module Ci
    class Lint
      class Result
        attr_reader :jobs, :merged_yaml, :errors, :warnings, :includes

        def initialize(jobs:, merged_yaml:, errors:, warnings:, includes:)
          @jobs = jobs
          @merged_yaml = merged_yaml
          @errors = errors
          @warnings = warnings
          @includes = includes
        end

        def valid?
          @errors.empty?
        end

        def status
          valid? ? :valid : :invalid
        end
      end

      LOG_MAX_DURATION_THRESHOLD = 2.seconds

      def initialize(project:, current_user:, sha: nil)
        @project = project
        @current_user = current_user
        @sha = sha || project&.repository&.commit&.sha
      end

      def validate(content, dry_run: false, ref: @project&.default_branch)
        if dry_run
          simulate_pipeline_creation(content, ref)
        else
          static_validation(content)
        end
      end

      private

      def simulate_pipeline_creation(content, ref)
        pipeline = ::Ci::CreatePipelineService
          .new(@project, @current_user, ref: ref)
          .execute(:push, dry_run: true, content: content)
          .payload

        Result.new(
          jobs: dry_run_convert_to_jobs(pipeline.stages),
          merged_yaml: pipeline.config_metadata.try(:[], :merged_yaml),
          errors: pipeline.error_messages.map(&:content),
          warnings: pipeline.warning_messages(limit: ::Gitlab::Ci::Warnings::MAX_LIMIT).map(&:content),
          includes: pipeline.config_metadata.try(:[], :includes)
        )
      end

      def static_validation(content)
        logger = build_logger

        result = yaml_processor_result(content, logger)

        Result.new(
          jobs: static_validation_convert_to_jobs(result),
          merged_yaml: result.config_metadata[:merged_yaml],
          errors: result.errors,
          warnings: result.warnings.take(::Gitlab::Ci::Warnings::MAX_LIMIT), # rubocop: disable CodeReuse/ActiveRecord
          includes: result.config_metadata[:includes]
        )
      ensure
        logger.commit(pipeline: ::Ci::Pipeline.new, caller: self.class.name)
      end

      def yaml_processor_result(content, logger)
        logger.instrument(:yaml_process) do
          Gitlab::Ci::YamlProcessor.new(content, project: @project,
                                                 user: @current_user,
                                                 sha: @sha,
                                                 logger: logger).execute
        end
      end

      def dry_run_convert_to_jobs(stages)
        stages.reduce([]) do |jobs, stage|
          jobs + stage.statuses.map do |job|
            {
              name: job.name,
              stage: stage.name,
              before_script: job.options[:before_script].to_a,
              script: job.options[:script].to_a,
              after_script: job.options[:after_script].to_a,
              tag_list: (job.tag_list if job.is_a?(::Ci::Build)).to_a,
              environment: job.options.dig(:environment, :name),
              when: job.when,
              allow_failure: job.allow_failure
            }
          end
        end
      end

      def static_validation_convert_to_jobs(result)
        jobs = []
        return jobs unless result.valid?

        result.stages.each do |stage_name|
          result.builds.each do |job|
            next unless job[:stage] == stage_name

            jobs << {
              name: job[:name],
              stage: stage_name,
              before_script: job.dig(:options, :before_script).to_a,
              script: job.dig(:options, :script).to_a,
              after_script: job.dig(:options, :after_script).to_a,
              tag_list: job[:tag_list].to_a,
              only: job[:only],
              except: job[:except],
              environment: job[:environment],
              when: job[:when],
              allow_failure: job[:allow_failure],
              needs: job.dig(:needs_attributes)
            }
          end
        end

        jobs
      end

      def build_logger
        Gitlab::Ci::Pipeline::Logger.new(project: @project) do |l|
          l.log_when do |observations|
            values = observations['yaml_process_duration_s']
            next false if values.empty?

            values.max >= LOG_MAX_DURATION_THRESHOLD
          end
        end
      end
    end
  end
end
