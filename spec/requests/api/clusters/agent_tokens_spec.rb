# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Clusters::AgentTokens do
  let_it_be(:agent) { create(:cluster_agent) }
  let_it_be(:agent_token_one) { create(:cluster_agent_token, agent: agent) }
  let_it_be(:agent_token_two) { create(:cluster_agent_token, agent: agent) }
  let_it_be(:project) { agent.project }
  let_it_be(:user) { agent.created_by_user }
  let_it_be(:unauthorized_user) { create(:user) }

  before_all do
    project.add_maintainer(user)
    project.add_guest(unauthorized_user)
  end

  describe 'GET /projects/:id/cluster_agents/:agent_id/tokens' do
    context 'with authorized user' do
      it 'returns tokens' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(response).to match_response_schema('public_api/v4/agent_tokens')
          expect(json_response.count).to eq(2)
          expect(json_response.first['name']).to eq(agent_token_one.name)
          expect(json_response.first['agent_id']).to eq(agent.id)
          expect(json_response.second['name']).to eq(agent_token_two.name)
          expect(json_response.second['agent_id']).to eq(agent.id)
        end
      end
    end

    context 'with unauthorized user' do
      it 'cannot access agent tokens' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'avoids N+1 queries', :request_store do
      # Establish baseline
      get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user)

      control = ActiveRecord::QueryRecorder.new do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user)
        expect(response).to have_gitlab_http_status(:ok)
      end

      # Now create a second record and ensure that the API does not execute
      # any more queries than before
      create(:cluster_agent_token, agent: agent)

      expect do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user)
      end.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id' do
    context 'with authorized user' do
      it 'returns an agent token' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{agent_token_one.id}", user)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/agent_token')
          expect(json_response['id']).to eq(agent_token_one.id)
          expect(json_response['name']).to eq(agent_token_one.name)
          expect(json_response['agent_id']).to eq(agent.id)
        end
      end

      it 'returns a 404 error if agent token id is not available' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      it 'cannot access single agent token' do
        get api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{agent_token_one.id}", unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'cannot access token from agent of another project' do
        another_project = create(:project, namespace: unauthorized_user.namespace)
        another_agent = create(:cluster_agent, project: another_project, created_by_user: unauthorized_user)

        get api("/projects/#{another_project.id}/cluster_agents/#{another_agent.id}/tokens/#{agent_token_one.id}",
                unauthorized_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/cluster_agents/:agent_id/tokens' do
    it 'creates a new agent token' do
      params = {
        name: 'test-token',
        description: 'Test description'
      }
      post(api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user), params: params)

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/agent_token_with_token')
        expect(json_response['name']).to eq(params[:name])
        expect(json_response['description']).to eq(params[:description])
        expect(json_response['agent_id']).to eq(agent.id)
      end
    end

    it 'returns a 400 error if name not given' do
      post api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 404 error if project does not exist' do
      post api("/projects/#{non_existing_record_id}/cluster_agents/tokens", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 error if agent does not exist' do
      post api("/projects/#{project.id}/cluster_agents/#{non_existing_record_id}/tokens", user),
           params: { name: "some" }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'with unauthorized user' do
      it 'prevents to create agent token' do
        post api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens", unauthorized_user),
             params: { name: "some" }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id' do
    it 'revokes agent token' do
      delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{agent_token_one.id}", user)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(agent_token_one.reload).to be_revoked
    end

    it 'returns a 404 error when revoking non existent agent token' do
      delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns a 404 if the user is unauthorized to revoke' do
      delete api("/projects/#{project.id}/cluster_agents/#{agent.id}/tokens/#{agent_token_one.id}", unauthorized_user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'cannot revoke token from agent of another project' do
      another_project = create(:project, namespace: unauthorized_user.namespace)
      another_agent = create(:cluster_agent, project: another_project, created_by_user: unauthorized_user)

      delete api("/projects/#{another_project.id}/cluster_agents/#{another_agent.id}/tokens/#{agent_token_one.id}",
                 unauthorized_user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
