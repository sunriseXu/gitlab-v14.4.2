# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::FetchGoogleIpListWorker do
  describe '#perform' do
    it 'returns success' do
      allow_next_instance_of(GoogleCloud::FetchGoogleIpListService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success })
      end

      expect(described_class.new.perform).to eq({ status: :success })
    end
  end
end
