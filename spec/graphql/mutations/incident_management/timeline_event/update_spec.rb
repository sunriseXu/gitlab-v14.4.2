# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::IncidentManagement::TimelineEvent::Update do
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be_with_reload(:timeline_event) do
    create(:incident_management_timeline_event, project: project, incident: incident)
  end

  let(:args) do
    {
      id: timeline_event_id,
      note: note,
      occurred_at: occurred_at
    }
  end

  let(:note) { 'Updated Note' }
  let(:timeline_event_id) { GitlabSchema.id_from_object(timeline_event).to_s }
  let(:occurred_at) { 1.minute.ago }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  describe '#resolve' do
    let(:current_user) { developer }

    subject(:resolve) { mutation_for(current_user).resolve(**args) }

    shared_examples 'failed update with a top-level access error' do |error|
      specify do
        expect { resolve }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          error || Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when user has permissions to update the timeline event' do
      context 'when timeline event exists' do
        it 'updates the timeline event' do
          expect { resolve }.to change { timeline_event.reload.note }.to(note)
            .and change { timeline_event.reload.occurred_at.to_s }.to(occurred_at.to_s)
        end

        it 'returns updated timeline event' do
          expect(resolve).to eq(
            timeline_event: timeline_event.reload,
            errors: []
          )
        end

        context 'when there is a validation error' do
          context 'when note is blank' do
            let(:note) { '' }

            it 'does not update the timeline event' do
              expect { resolve }.not_to change { timeline_event.reload.updated_at }
            end

            it 'responds with error' do
              expect(resolve).to eq(timeline_event: nil, errors: ["Note can't be blank"])
            end
          end

          context 'when occurred_at is blank' do
            let(:occurred_at) { '' }

            it 'does not update the timeline event' do
              expect { resolve }.not_to change { timeline_event.reload.updated_at }
            end

            it 'responds with error' do
              expect(resolve).to eq(timeline_event: nil, errors: ["Occurred at can't be blank"])
            end
          end

          context 'when occurred_at is invalid' do
            let(:occurred_at) { 'invalid date' }

            it 'does not update the timeline event' do
              expect { resolve }.not_to change { timeline_event.reload.updated_at }
            end

            it 'responds with error' do
              expect(resolve).to eq(timeline_event: nil, errors: ["Occurred at can't be blank"])
            end
          end
        end
      end

      context 'when timeline event cannot be found' do
        let(:timeline_event_id) do
          Gitlab::GlobalId.build(
            nil,
            model_name: ::IncidentManagement::TimelineEvent.name,
            id: non_existing_record_id
          ).to_s
        end

        it_behaves_like 'failed update with a top-level access error'
      end
    end

    context 'when user does not have permissions to update the timeline event' do
      let(:current_user) { reporter }

      it_behaves_like 'failed update with a top-level access error'
    end
  end

  private

  def mutation_for(user)
    described_class.new(object: nil, context: { current_user: user }, field: nil)
  end
end
