# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountBulkImportsEntitiesMetric do
  let_it_be(:user) { create(:user) }
  let_it_be(:bulk_import_projects) do
    create_list(:bulk_import_entity, 2, source_type: 'project_entity', created_at: 3.weeks.ago, status: 2)
    create(:bulk_import_entity, source_type: 'project_entity', created_at: 3.weeks.ago, status: 0)
  end

  let_it_be(:bulk_import_groups) do
    create_list(:bulk_import_entity, 2, source_type: 'group_entity', created_at: 3.weeks.ago, status: 2)
    create(:bulk_import_entity, source_type: 'group_entity', created_at: 3.weeks.ago, status: 0)
  end

  let_it_be(:old_bulk_import_project) do
    create(:bulk_import_entity, source_type: 'project_entity', created_at: 2.months.ago, status: 2)
  end

  context 'with no source_type' do
    context 'with all time frame' do
      let(:expected_value) { 7 }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""
      end

      it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all', options: {}
    end

    context 'for 28d time frame' do
      let(:expected_value) { 6 }
      let(:start) { 30.days.ago.to_s(:db) }
      let(:finish) { 2.days.ago.to_s(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
      end

      it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d', options: {}
    end
  end

  context 'with invalid source_type' do
    it 'raises ArgumentError' do
      expect { described_class.new(time_frame: 'all', options: { source_type: 'random' }) }
        .to raise_error(ArgumentError, /source_type/)
    end
  end

  context 'with source_type project_entity' do
    context 'with all time frame' do
      let(:expected_value) { 4 }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"source_type\" = 1"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { source_type: 'project_entity' }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 3 }
      let(:start) { 30.days.ago.to_s(:db) }
      let(:finish) { 2.days.ago.to_s(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"\
        " AND \"bulk_import_entities\".\"source_type\" = 1"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { source_type: 'project_entity' }
    end
  end

  context 'with source_type group_entity' do
    context 'with all time frame' do
      let(:expected_value) { 3 }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"source_type\" = 0"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { source_type: 'group_entity' }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 3 }
      let(:start) { 30.days.ago.to_s(:db) }
      let(:finish) { 2.days.ago.to_s(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"\
        " AND \"bulk_import_entities\".\"source_type\" = 0"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { source_type: 'group_entity' }
    end
  end

  context 'with entity status' do
    context 'with all time frame' do
      let(:expected_value) { 5 }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"status\" = 2"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { status: 2 }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 4 }
      let(:start) { 30.days.ago.to_s(:db) }
      let(:finish) { 2.days.ago.to_s(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"\
        " AND \"bulk_import_entities\".\"status\" = 2"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { status: 2 }
    end
  end

  context 'with entity status and source_type' do
    context 'with all time frame' do
      let(:expected_value) { 3 }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"source_type\" = 1 AND \"bulk_import_entities\".\"status\" = 2"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { status: 2, source_type: 'project_entity' }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 2 }
      let(:start) { 30.days.ago.to_s(:db) }
      let(:finish) { 2.days.ago.to_s(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\""\
        " WHERE \"bulk_import_entities\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"\
        " AND \"bulk_import_entities\".\"source_type\" = 1 AND \"bulk_import_entities\".\"status\" = 2"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { status: 2, source_type: 'project_entity' }
    end
  end
end
