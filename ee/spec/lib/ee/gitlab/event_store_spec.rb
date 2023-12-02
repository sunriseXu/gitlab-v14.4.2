# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore do
  describe '.instance' do
    it 'returns a store with CE and EE subscriptions' do
      instance = described_class.instance

      expect(instance.subscriptions.keys).to include(
        ::Ci::JobArtifactsDeletedEvent,
        ::Ci::PipelineCreatedEvent,
        ::Members::MembersAddedEvent,
        ::Repositories::KeepAroundRefsCreatedEvent,
        ::MergeRequests::ApprovedEvent
      )
    end
  end
end
