# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrationsHelpers do
  let(:helper_class) do
    Class.new.tap do |klass|
      klass.include described_class
      allow(klass).to receive(:metadata).and_return(metadata)
    end
  end

  let(:metadata) { {} }
  let(:helper) { helper_class.new }

  describe '#active_record_base' do
    it 'returns the main base model' do
      expect(helper.active_record_base).to eq(ActiveRecord::Base)
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup
      end

      it 'returns the CI base model' do
        expect(helper.active_record_base(database: :ci)).to eq(Ci::ApplicationRecord)
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup
      end

      it 'returns the main base model' do
        expect(helper.active_record_base(database: :ci)).to eq(ActiveRecord::Base)
      end
    end

    it 'raises ArgumentError for bad database argument' do
      expect { helper.active_record_base(database: :non_existent) }.to raise_error(ArgumentError)
    end
  end

  describe '#table' do
    it 'creates a class based on main base model' do
      klass = helper.table(:projects)
      expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
    end

    context 'ci database configured' do
      before do
        skip_if_multiple_databases_not_setup
      end

      it 'create a class based on the CI base model' do
        klass = helper.table(:ci_builds, database: :ci)
        expect(klass.connection_specification_name).to eq('Ci::ApplicationRecord')
      end
    end

    context 'ci database not configured' do
      before do
        skip_if_multiple_databases_are_setup
      end

      it 'creates a class based on main base model' do
        klass = helper.table(:ci_builds, database: :ci)
        expect(klass.connection_specification_name).to eq('ActiveRecord::Base')
      end
    end
  end
end
