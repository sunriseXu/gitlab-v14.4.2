# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::ChangeFailureRate do
  let(:stage) { build(:cycle_analytics_group_stage) }
  let(:user) { build(:user) }

  let(:options) do
    {
      from: 5.days.ago,
      to: 2.days.ago
    }
  end

  subject(:result) { described_class.new(stage: stage, current_user: user, options: options).value }

  context 'when the DORA service returns non-successful status' do
    it 'returns nil' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :error })
      end

      expect(result).to eq(nil)
    end
  end

  context 'when the DORA service returns 0 as value' do
    it 'returns "0" value' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success, data: 0 })
      end

      expect(result.to_s).to eq('0')
    end
  end

  context 'when the DORA service returns the value' do
    it 'returns the value in days' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success, data: 0.85 })
      end

      expect(result.to_s).to eq('85.0')
    end
  end

  describe '#links' do
    subject { described_class.new(stage: stage, current_user: user, options: options).links }

    it 'displays documentation link and group dashboard link' do
      helpers = Gitlab::Routing.url_helpers

      expect(subject).to match_array(
        [
          {
            "name" => _('Change Failure Rate'),
            "url" => helpers.group_analytics_ci_cd_analytics_path(stage.parent, tab: 'change-failure-rate'),
            "label" => s_('ValueStreamAnalytics|Dashboard')
          },
          {
            "name" => _('Change Failure Rate'),
            "url" => helpers.help_page_path('user/analytics/index', anchor: 'change-failure-rate'),
            "docs_link" => true,
            "label" => s_('ValueStreamAnalytics|Go to docs')
          }
        ]
      )
    end

    context 'when the stage parent is a project' do
      let(:stage) { build(:cycle_analytics_project_stage) }

      it 'displays documentation link and group dashboard link' do
        helpers = Gitlab::Routing.url_helpers

        expect(subject).to match_array(
          [
            {
              "name" => _('Change Failure Rate'),
              "url" => helpers.charts_project_pipelines_path(stage.parent, chart: 'change-failure-rate'),
              "label" => s_('ValueStreamAnalytics|Dashboard')
            },
            {
              "name" => _('Change Failure Rate'),
              "url" => helpers.help_page_path('user/analytics/index', anchor: 'change-failure-rate'),
              "docs_link" => true,
              "label" => s_('ValueStreamAnalytics|Go to docs')
            }
          ]
        )
      end
    end
  end
end
