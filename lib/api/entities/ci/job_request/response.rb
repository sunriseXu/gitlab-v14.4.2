# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Response < Grape::Entity
          expose :id
          expose :token
          expose :allow_git_fetch

          expose :job_info, using: Entities::Ci::JobRequest::JobInfo do |model|
            model
          end

          expose :git_info, using: Entities::Ci::JobRequest::GitInfo do |model|
            model
          end

          expose :runner_info, using: Entities::Ci::JobRequest::RunnerInfo do |model|
            model
          end

          expose :runner_variables, as: :variables
          expose :steps, using: Entities::Ci::JobRequest::Step
          expose :image, using: Entities::Ci::JobRequest::Image
          expose :services, using: Entities::Ci::JobRequest::Service
          expose :artifacts, using: Entities::Ci::JobRequest::Artifacts
          expose :cache, using: Entities::Ci::JobRequest::Cache
          expose :credentials, using: Entities::Ci::JobRequest::Credentials
          expose :features
          expose :dependencies do |job, options|
            Entities::Ci::JobRequest::Dependency.represent(job.all_dependencies, options.merge(running_job: job))
          end
        end
      end
    end
  end
end

API::Entities::Ci::JobRequest::Response.prepend_mod_with('API::Entities::Ci::JobRequest::Response')
