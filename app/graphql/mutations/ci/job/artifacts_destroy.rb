# frozen_string_literal: true

module Mutations
  module Ci
    module Job
      class ArtifactsDestroy < Base
        graphql_name 'JobArtifactsDestroy'

        authorize :destroy_artifacts

        field :job,
              Types::Ci::JobType,
              null: true,
              description: 'Job with artifacts to be deleted.'

        field :destroyed_artifacts_count,
              GraphQL::Types::Int,
              null: false,
              description: 'Number of artifacts deleted.'

        def find_object(id: )
          GlobalID::Locator.locate(id)
        end

        def resolve(id:)
          job = authorized_find!(id: id)

          result = ::Ci::JobArtifacts::DestroyBatchService.new(job.job_artifacts, pick_up_at: Time.current).execute
          {
            job: job,
            destroyed_artifacts_count: result[:destroyed_artifacts_count],
            errors: Array(result[:errors])
          }
        end
      end
    end
  end
end
