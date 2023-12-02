# frozen_string_literal: true

module API
  module Clusters
    class AgentTokens < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :kubernetes_management

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :agent_id, type: Integer, desc: 'The ID of an agent'
        end
        resource ':id/cluster_agents/:agent_id' do
          resource :tokens do
            desc 'List agent tokens' do
              detail 'This feature was introduced in GitLab 15.0.'
              success Entities::Clusters::AgentTokenBasic
            end
            params do
              use :pagination
            end
            get do
              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              present paginate(agent.agent_tokens), with: Entities::Clusters::AgentTokenBasic
            end

            desc 'Get a single agent token' do
              detail 'This feature was introduced in GitLab 15.0.'
              success Entities::Clusters::AgentToken
            end
            params do
              requires :token_id, type: Integer, desc: 'The ID of the agent token'
            end
            get ':token_id' do
              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              token = agent.agent_tokens.find(params[:token_id])

              present token, with: Entities::Clusters::AgentToken
            end

            desc 'Create an agent token' do
              detail 'This feature was introduced in GitLab 15.0.'
              success Entities::Clusters::AgentTokenWithToken
            end
            params do
              requires :name, type: String, desc: 'The name for the token'
              optional :description, type: String, desc: 'The description for the token'
            end
            post do
              authorize! :create_cluster, user_project

              token_params = declared_params(include_missing: false)

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              result = ::Clusters::AgentTokens::CreateService.new(
                container: agent.project, current_user: current_user, params: token_params.merge(agent_id: agent.id)
              ).execute

              bad_request!(result[:message]) if result[:status] == :error

              present result[:token], with: Entities::Clusters::AgentTokenWithToken
            end

            desc 'Revoke an agent token' do
              detail 'This feature was introduced in GitLab 15.0.'
            end
            params do
              requires :token_id, type: Integer, desc: 'The ID of the agent token'
            end
            delete ':token_id' do
              authorize! :admin_cluster, user_project

              agent = ::Clusters::AgentsFinder.new(user_project, current_user).find(params[:agent_id])

              token = agent.agent_tokens.find(params[:token_id])

              # Skipping explicit error handling and relying on exceptions
              token.revoked!

              status :no_content
            end
          end
        end
      end
    end
  end
end
