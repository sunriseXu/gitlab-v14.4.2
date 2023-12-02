# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let(:args) { { note: 'note', occurred_at: Time.current } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_incident_management_timeline_event) }

  describe '#resolve' do
    subject(:resolve) { mutation_for(project, current_user).resolve(incident_id: incident.to_global_id, **args) }

    context 'when a user has permissions to create a timeline event' do
      let(:expected_timeline_event) do
        instance_double(
          'IncidentManagement::TimelineEvent',
          note: args[:note],
          occurred_at: args[:occurred_at].to_s,
          incident: incident,
          author: current_user,
          promoted_from_note: nil,
          editable: true
        )
      end

      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'creating an incident timeline event'

      context 'when TimelineEvents::CreateService responds with an error' do
        let(:args) { {} }

        it_behaves_like 'responding with an incident timeline errors',
          errors: ["Occurred at can't be blank, Note can't be blank, and Note html can't be blank"]
      end
    end

    it_behaves_like 'failing to create an incident timeline event'
  end

  private

  def mutation_for(project, user)
    described_class.new(object: project, context: { current_user: user }, field: nil)
  end
end
