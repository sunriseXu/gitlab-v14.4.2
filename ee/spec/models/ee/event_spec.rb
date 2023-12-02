# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Event do
  describe '#visible_to_user?' do
    let_it_be(:non_member) { create(:user) }
    let_it_be(:member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:author) { create(:author) }
    let_it_be(:admin) { create(:admin) }

    let(:users) { [non_member, member, reporter, guest, author, admin] }

    let(:epic) { create(:epic, group: group, author: author) }
    let(:note_on_epic) { create(:note, :on_epic, noteable: epic) }
    let(:event) { described_class.new(group: group, target: target, author: author) }

    before do
      stub_licensed_features(epics: true)

      if defined?(group)
        group.add_developer(member)
        group.add_guest(guest)
      end
    end

    RSpec::Matchers.define :be_visible_to do |user|
      match do |event|
        event.visible_to_user?(user)
      end

      failure_message do |event|
        "expected that #{event} should be visible to #{user}"
      end

      failure_message_when_negated do |event|
        "expected that #{event} would not be visible to #{user}"
      end
    end

    RSpec::Matchers.define :have_access_to do |event|
      match do |user|
        event.visible_to_user?(user)
      end

      failure_message do |user|
        "expected that #{event} should be visible to #{user}"
      end

      failure_message_when_negated do |user|
        "expected that #{event} would not be visible to #{user}"
      end
    end

    shared_examples 'visible to group members only' do
      it 'is not visible to other users', :aggregate_failures do
        expect(event).not_to be_visible_to(non_member)
        expect(event).not_to be_visible_to(author)

        expect(event).to be_visible_to(member)
        expect(event).to be_visible_to(guest)
      end

      context 'when admin mode enabled', :enable_admin_mode do
        it 'is visible to admin', :aggregate_failures do
          expect(event).to be_visible_to(admin)
        end
      end

      context 'when admin mode disabled' do
        it 'is not visible to admin', :aggregate_failures do
          expect(event).not_to be_visible_to(admin)
        end
      end
    end

    shared_examples 'visible to everybody' do
      it 'is visible to other users', :aggregate_failures do
        expect(users).to all(have_access_to(event))
      end
    end

    context 'epic event' do
      let(:target) { epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'on private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end

    context 'epic note event' do
      let(:target) { note_on_epic }

      context 'on public group' do
        let(:group) { create(:group, :public) }

        it_behaves_like 'visible to everybody'
      end

      context 'private group' do
        let(:group) { create(:group, :private) }

        it_behaves_like 'visible to group members only'
      end
    end
  end

  describe '#set_last_repository_updated_at' do
    let(:project) { create(:project) }
    let(:project_repository_state) { create(:repository_state, project: project) }

    it 'always updates the project_repository_state record', :freeze_time do
      last_known_timestamp = (Event::REPOSITORY_UPDATED_AT_INTERVAL - 1.minute).ago
      project.update!(last_repository_updated_at: last_known_timestamp)
      project_repository_state.update!(last_repository_updated_at: last_known_timestamp)

      create_push_event(project, project.first_owner)

      expect { project.reload }.not_to change { project.last_repository_updated_at }
      expect do
        project_repository_state.reload
      end.to change { project_repository_state.last_repository_updated_at }.to(Time.current)
    end

    def create_push_event(project, user)
      event = create(:push_event, project: project, author: user)

      create(:push_event_payload,
            event: event,
            commit_to: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
            commit_count: 0,
            ref: 'master')

      event
    end
  end
end
