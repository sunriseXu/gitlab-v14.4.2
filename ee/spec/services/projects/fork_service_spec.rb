# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ForkService do
  include ProjectForksHelper

  describe 'fork by user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, namespace: group) }
    let_it_be(:event_type) { "project_fork_operation" }

    before do
      project.add_member(user, :developer)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    subject(:execute) { described_class.new(project, user).execute }

    it 'call auditor with currect context' do
      audit_context = {
        name: event_type,
        stream_only: true,
        author: user,
        scope: project,
        target: project,
        message: "Forked project to #{user.namespace.path}/#{project.path}"
      }
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(audit_context))

      subject
    end

    context "with license feature external_audit_events" do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      it 'sends correct event type in audit event stream' do
        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(event_type, nil, anything)

        subject
      end
    end

    context "without license feature external_audit_events" do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it 'not sends audit event stream' do
        expect(AuditEvents::AuditEventStreamingWorker).not_to receive(:perform_async)

        subject
      end
    end
  end
end
