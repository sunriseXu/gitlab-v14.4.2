# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Auditor do
  let(:name) { 'audit_operation' }
  let(:author) { create(:user, :with_sign_ins) }
  let(:group) { create(:group) }
  let(:provider) { 'standard' }
  let(:context) do
    { name: name,
      author: author,
      scope: group,
      target: group,
      authentication_event: true,
      authentication_provider: provider,
      message: "Signed in using standard authentication" }
  end

  let(:logger) { instance_spy(Gitlab::AuditJsonLogger) }

  subject(:auditor) { described_class }

  describe '.audit' do
    context 'when authentication event' do
      let(:audit!) { auditor.audit(context) }

      it 'creates an authentication event' do
        expect(AuthenticationEvent).to receive(:new).with(
          {
            user: author,
            user_name: author.name,
            ip_address: author.current_sign_in_ip,
            result: AuthenticationEvent.results[:success],
            provider: provider
          }
        ).and_call_original

        audit!

        authentication_event = AuthenticationEvent.last

        expect(authentication_event.user).to eq(author)
        expect(authentication_event.user_name).to eq(author.name)
        expect(authentication_event.ip_address).to eq(author.current_sign_in_ip)
        expect(authentication_event.provider).to eq(provider)
      end

      it 'logs audit events to database', :aggregate_failures do
        freeze_time do
          audit!

          audit_event = AuditEvent.last

          expect(audit_event.author_id).to eq(author.id)
          expect(audit_event.entity_id).to eq(group.id)
          expect(audit_event.entity_type).to eq(group.class.name)
          expect(audit_event.created_at).to eq(Time.zone.now)
          expect(audit_event.details[:target_id]).to eq(group.id)
          expect(audit_event.details[:target_type]).to eq(group.class.name)
        end
      end

      it 'logs audit events to file' do
        expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

        audit!

        expect(logger).to have_received(:info).with(
          hash_including(
            'author_id' => author.id,
            'author_name' => author.name,
            'entity_id' => group.id,
            'entity_type' => group.class.name,
            'details' => kind_of(Hash)
          )
        )
      end

      context 'when overriding the create datetime' do
        let(:context) do
          { name: name,
            author: author,
            scope: group,
            target: group,
            created_at: 3.weeks.ago,
            authentication_event: true,
            authentication_provider: provider,
            message: "Signed in using standard authentication" }
        end

        it 'logs audit events to database', :aggregate_failures do
          freeze_time do
            audit!

            audit_event = AuditEvent.last

            expect(audit_event.author_id).to eq(author.id)
            expect(audit_event.entity_id).to eq(group.id)
            expect(audit_event.entity_type).to eq(group.class.name)
            expect(audit_event.created_at).to eq(3.weeks.ago)
            expect(audit_event.details[:target_id]).to eq(group.id)
            expect(audit_event.details[:target_type]).to eq(group.class.name)
          end
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'author_id' => author.id,
                'author_name' => author.name,
                'entity_id' => group.id,
                'entity_type' => group.class.name,
                'details' => kind_of(Hash),
                'created_at' => 3.weeks.ago.iso8601(3)
              )
            )
          end
        end
      end

      context 'when overriding the additional_details' do
        additional_details = { action: :custom, from: false, to: true }
        let(:context) do
          { name: name,
            author: author,
            scope: group,
            target: group,
            created_at: Time.zone.now,
            additional_details: additional_details,
            authentication_event: true,
            authentication_provider: provider,
            message: "Signed in using standard authentication" }
        end

        it 'logs audit events to database' do
          freeze_time do
            audit!

            expect(AuditEvent.last.details).to include(additional_details)
          end
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'details' => hash_including('action' => 'custom', 'from' => 'false', 'to' => 'true'),
                'action' => 'custom',
                'from' => 'false',
                'to' => 'true'
              )
            )
          end
        end
      end

      context 'when overriding the target_details' do
        target_details = "this is my target details"
        let(:context) do
          {
            name: name,
            author: author,
            scope: group,
            target: group,
            created_at: Time.zone.now,
            target_details: target_details,
            authentication_event: true,
            authentication_provider: provider,
            message: "Signed in using standard authentication"
          }
        end

        it 'logs audit events to database' do
          freeze_time do
            audit!

            audit_event = AuditEvent.last
            expect(audit_event.details).to include({ target_details: target_details })
            expect(audit_event.target_details).to eq(target_details)
          end
        end

        it 'logs audit events to file' do
          freeze_time do
            expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

            audit!

            expect(logger).to have_received(:info).with(
              hash_including(
                'details' => hash_including('target_details' => target_details),
                'target_details' => target_details
              )
            )
          end
        end
      end
    end

    context 'when authentication event is false' do
      let(:context) do
        { name: name, author: author, scope: group,
          target: group, authentication_event: false, message: "sample message" }
      end

      it 'does not create an authentication event' do
        expect { auditor.audit(context) }.not_to change(AuthenticationEvent, :count)
      end
    end

    context 'when authentication event is invalid' do
      let(:audit!) { auditor.audit(context) }

      before do
        allow(AuthenticationEvent).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks error' do
        audit!

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          kind_of(ActiveRecord::RecordInvalid),
          { audit_operation: name }
        )
      end

      it 'does not throw exception' do
        expect { auditor.audit(context) }.not_to raise_exception
      end
    end

    context 'when audit events are invalid' do
      let(:audit!) { auditor.audit(context) }

      before do
        allow(AuditEvent).to receive(:bulk_insert!).and_raise(ActiveRecord::RecordInvalid)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks error' do
        audit!

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          kind_of(ActiveRecord::RecordInvalid),
          { audit_operation: name }
        )
      end

      it 'does not throw exception' do
        expect { auditor.audit(context) }.not_to raise_exception
      end
    end
  end
end
