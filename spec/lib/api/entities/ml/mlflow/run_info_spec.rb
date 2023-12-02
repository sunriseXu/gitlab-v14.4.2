# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ml::Mlflow::RunInfo do
  let_it_be(:candidate) { create(:ml_candidates) }

  subject { described_class.new(candidate).as_json }

  context 'when start_time is nil' do
    it { expect(subject[:start_time]).to eq(0) }
  end

  context 'when start_time is not nil' do
    before do
      allow(candidate).to receive(:start_time).and_return(1234)
    end

    it { expect(subject[:start_time]).to eq(1234) }
  end

  describe 'end_time' do
    context 'when nil' do
      it { is_expected.not_to have_key(:end_time) }
    end

    context 'when not nil' do
      before do
        allow(candidate).to receive(:end_time).and_return(1234)
      end

      it { expect(subject[:end_time]).to eq(1234) }
    end
  end

  describe 'experiment_id' do
    it 'is the experiment iid as string' do
      expect(subject[:experiment_id]).to eq(candidate.experiment.iid.to_s)
    end
  end

  describe 'run_id' do
    it 'is the iid as string' do
      expect(subject[:run_id]).to eq(candidate.iid.to_s)
    end
  end

  describe 'run_uuid' do
    it 'is the iid as string' do
      expect(subject[:run_uuid]).to eq(candidate.iid.to_s)
    end
  end

  describe 'artifact_uri' do
    it 'is not implemented' do
      expect(subject[:artifact_uri]).to eq('not_implemented')
    end
  end

  describe 'lifecycle_stage' do
    it 'is active' do
      expect(subject[:lifecycle_stage]).to eq('active')
    end
  end
end
