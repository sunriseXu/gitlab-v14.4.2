# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::LeadTime do
  let(:stage) { build(:cycle_analytics_group_stage) }
  let(:user) { build(:user) }

  let(:options) do
    {
      from: 5.days.ago,
      to: 2.days.ago
    }
  end

  subject(:result) { described_class.new(stage: stage, current_user: user, options: options).value }

  describe '#links' do
    subject { described_class.new(stage: stage, current_user: user, options: options).links }

    it 'returns docs link and group dashboard link' do
      helpers = Gitlab::Routing.url_helpers

      expect(subject).to match_array(
        [
          { "name" => _('Lead Time'),
            "url" => helpers.group_issues_analytics_path(stage.parent),
            "label" => s_('ValueStreamAnalytics|Dashboard') },
          { "name" => _('Lead Time'),
            "url" => helpers.help_page_path('user/analytics/index', anchor: 'definitions'),
            "docs_link" => true,
            "label" => s_('ValueStreamAnalytics|Go to docs') }
        ]
      )
    end

    context 'for project stage' do
      let(:stage) { build(:cycle_analytics_project_stage) }

      it 'returns project dashboard link' do
        helpers = Gitlab::Routing.url_helpers

        expect(subject).to match_array(
          [
            { "name" => _('Lead Time'),
              "url" => helpers.project_analytics_issues_analytics_path(stage.parent),
              "label" => s_('ValueStreamAnalytics|Dashboard') },
            { "name" => _('Lead Time'),
              "url" => helpers.help_page_path('user/analytics/index', anchor: 'definitions'),
              "docs_link" => true,
              "label" => s_('ValueStreamAnalytics|Go to docs') }
          ]
        )
      end
    end
  end
end
