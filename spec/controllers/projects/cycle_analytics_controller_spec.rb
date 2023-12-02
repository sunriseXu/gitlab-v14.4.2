# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CycleAnalyticsController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context "counting page views for 'show'" do
    it 'increases the counter' do
      expect(Gitlab::UsageDataCounters::CycleAnalyticsCounter).to receive(:count).with(:views)

      get(:show,
          params: {
            namespace_id: project.namespace,
            project_id: project
          })

      expect(response).to be_successful
    end
  end

  context 'tracking visits to html page' do
    it_behaves_like 'tracking unique visits', :show do
      let(:request_params) { { namespace_id: project.namespace, project_id: project } }
      let(:target_id) { 'p_analytics_valuestream' }
    end

    it_behaves_like 'Snowplow event tracking' do
      subject { get :show, params: request_params, format: :html }

      let(:request_params) { { namespace_id: project.namespace, project_id: project } }
      let(:feature_flag_name) { :route_hll_to_snowplow_phase2 }
      let(:category) { described_class.name }
      let(:action) { 'perform_analytics_usage_action' }
      let(:namespace) { project.namespace }
      let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
      let(:property) { 'p_analytics_valuestream' }
    end
  end

  include_examples GracefulTimeoutHandling
end
