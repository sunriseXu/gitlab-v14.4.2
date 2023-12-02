# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvent do
  describe 'validations' do
    include_examples 'validates IP address' do
      let(:attribute) { :ip_address }
      let(:object) { create(:audit_event) }
    end
  end

  describe 'callbacks' do
    describe '#parallel_persist' do
      shared_examples 'a parallel persisted field' do
        using RSpec::Parameterized::TableSyntax

        where(:column, :details, :expected_value) do
          :value | nil            | :value
          nil    | :value         | :value
          :value | :another_value | :value
          nil    | nil            | nil
        end

        with_them do
          let(:values) { { value: value, another_value: "#{value}88" } }

          let(:audit_event) do
            build(:audit_event, name => values[column], details: { name => values[details] })
          end

          it 'sets both values to be the same', :aggregate_failures do
            audit_event.validate

            expect(audit_event[name]).to eq(values[expected_value])
            expect(audit_event.details[name]).to eq(values[expected_value])
          end
        end
      end

      context 'wih author_name' do
        let(:name) { :author_name }
        let(:value) { 'Mary Poppins' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with entity_path' do
        let(:name) { :entity_path }
        let(:value) { 'gitlab-org' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_details' do
        let(:name) { :target_details }
        let(:value) { 'gitlab-org/gitlab' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_type' do
        let(:name) { :target_type }
        let(:value) { 'Project' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_id' do
        let(:name) { :target_id }
        let(:value) { 8 }

        it_behaves_like 'a parallel persisted field'
      end
    end
  end

  it 'sanitizes custom_message in the details hash' do
    audit_event = create(:project_audit_event, details: { target_id: 678, custom_message: '<strong>Arnold</strong>' })

    expect(audit_event.details).to include(
      target_id: 678,
      custom_message: 'Arnold'
    )
  end

  describe '#as_json' do
    context 'ip_address' do
      subject { build(:group_audit_event, ip_address: '192.168.1.1').as_json }

      it 'overrides the ip_address with its string value' do
        expect(subject['ip_address']).to eq('192.168.1.1')
      end
    end
  end

  describe '#author' do
    subject { audit_event.author }

    context "when the target type is not Ci::Runner" do
      let(:audit_event) { build(:project_audit_event, target_id: 678) }

      it 'returns a NullAuthor' do
        expect(::Gitlab::Audit::NullAuthor).to receive(:for)
          .and_call_original
          .once

        is_expected.to be_a_kind_of(::Gitlab::Audit::NullAuthor)
      end
    end

    context 'when the target type is Ci::Runner and details contain runner_registration_token' do
      let(:audit_event) { build(:project_audit_event, target_type: ::Ci::Runner.name, target_id: 678, details: { runner_registration_token: 'abc123' }) }

      it 'returns a CiRunnerTokenAuthor' do
        expect(::Gitlab::Audit::CiRunnerTokenAuthor).to receive(:new)
          .with(audit_event)
          .and_call_original
          .once

        is_expected.to be_an_instance_of(::Gitlab::Audit::CiRunnerTokenAuthor)
      end

      it 'name consists of prefix and token' do
        expect(subject.name).to eq('Registration token: abc123')
      end
    end
  end
end
