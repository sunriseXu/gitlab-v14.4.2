# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore::Event do
  let(:event_class) { stub_const('TestEvent', Class.new(described_class)) }
  let(:event) { event_class.new(data: data) }
  let(:data) { { project_id: 123, project_path: 'org/the-project' } }

  context 'when schema is not defined' do
    it 'raises an error on initialization' do
      expect { event }.to raise_error(NotImplementedError)
    end
  end

  context 'when schema is defined' do
    before do
      event_class.class_eval do
        def schema
          {
            'required' => ['project_id'],
            'type' => 'object',
            'properties' => {
              'project_id' => { 'type' => 'integer' },
              'project_path' => { 'type' => 'string' }
            }
          }
        end
      end
    end

    describe 'schema validation' do
      context 'when data matches the schema' do
        it 'initializes the event correctly' do
          expect(event.data).to eq(data)
        end
      end

      context 'when required properties are present as well as unknown properties' do
        let(:data) { { project_id: 123, unknown_key: 'unknown_value' } }

        it 'initializes the event correctly' do
          expect(event.data).to eq(data)
        end
      end

      context 'when some properties are missing' do
        let(:data) { { project_path: 'org/the-project' } }

        it 'expects all properties to be present' do
          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent, /does not match the defined schema/)
        end
      end

      context 'when data is not a Hash' do
        let(:data) { 123 }

        it 'raises an error' do
          expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent, 'Event data must be a Hash')
        end
      end
    end
  end
end
