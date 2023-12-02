# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ContainerRegistryEvent do
  let(:secret_token) { 'secret_token' }
  let(:events) { [{ action: 'push' }] }
  let(:registry_headers) { { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON } }

  describe 'POST /container_registry_event/events' do
    before do
      allow(Gitlab.config.registry).to receive(:notification_secret) { secret_token }
    end

    subject(:post_events) do
      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => secret_token)
    end

    it 'returns 200 status and events are passed to event handler' do
      event = spy(:event)
      allow(::ContainerRegistry::Event).to receive(:new).and_return(event)
      expect(event).to receive(:supported?).and_return(true)

      post_events

      expect(event).to have_received(:handle!).once
      expect(event).to have_received(:track!).once
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 401 error status when token is invalid' do
      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => 'invalid_token')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the event should update project statistics' do
      let_it_be(:project) { create(:project) }

      let(:events) do
        [
          {
            action: 'push',
            target: {
              tag: 'latest',
              repository: project.full_path
            }
          },
          {
            action: 'delete',
            target: {
              tag: 'latest',
              repository: project.full_path
            }
          }
        ]
      end

      it 'enqueues a project statistics update twice' do
        expect(ProjectCacheWorker)
          .to receive(:perform_async)
          .with(project.id, [], [:container_registry_size])
          .twice.and_call_original

        expect { post_events }.to change { ProjectCacheWorker.jobs.size }.from(0).to(1)
      end
    end
  end
end
