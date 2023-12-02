# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every metric definition' do
  include UsageDataHelpers

  let(:usage_ping) { Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values) }
  let(:ignored_usage_ping_key_patterns) do
    %w(
      license_add_ons
      testing_total_unique_counts
      user_auth_by_provider
    ).freeze
  end

  let(:usage_ping_key_paths) do
    parse_usage_ping_keys(usage_ping)
      .flatten
      .grep_v(Regexp.union(ignored_usage_ping_key_patterns))
      .sort
  end

  let(:ignored_metric_files_key_patterns) do
    %w(
      ci_runners_online
      mock_ci
      mock_monitoring
      user_auth_by_provider
      p_ci_templates_5_min_production_app
      p_ci_templates_aws_cf_deploy_ec2
      p_ci_templates_auto_devops_build
      p_ci_templates_auto_devops_deploy
      p_ci_templates_auto_devops_deploy_latest
      p_ci_templates_implicit_auto_devops_build
      p_ci_templates_implicit_auto_devops_deploy_latest
      p_ci_templates_implicit_auto_devops_deploy
    ).freeze
  end

  let(:events_not_defined_yet) do
    %w(
      redis_hll_counters.incident_management.incident_management_timeline_event_created_monthly
      redis_hll_counters.incident_management.incident_management_timeline_event_created_weekly
      redis_hll_counters.incident_management.incident_management_timeline_event_deleted_monthly
      redis_hll_counters.incident_management.incident_management_timeline_event_deleted_weekly
      redis_hll_counters.incident_management.incident_management_timeline_event_edited_monthly
      redis_hll_counters.incident_management.incident_management_timeline_event_edited_weekly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_created_weekly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_created_monthly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_deleted_weekly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_deleted_monthly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_visited_weekly
      redis_hll_counters.incident_management.incident_management_issuable_resource_link_visited_monthly
      redis_hll_counters.manage.unique_active_user_monthly
      redis_hll_counters.manage.unique_active_user_weekly
      redis_hll_counters.quickactions.i_quickactions_ready_monthly
      redis_hll_counters.quickactions.i_quickactions_ready_weekly
      redis_hll_counters.environments.users_visiting_environments_pages_weekly
    )
  end

  let(:metric_files_key_paths) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .reject { |k, v| v.status == 'removed' || v.key_path =~ Regexp.union(ignored_metric_files_key_patterns) }
      .keys
      .sort
  end

  let(:metric_files_with_schema) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .select { |k, v| v.respond_to?(:value_json_schema) }
  end

  # Recursively traverse nested Hash of a generated Usage Ping to return an Array of key paths
  # in the dotted format used in metric definition YAML files, e.g.: 'count.category.metric_name'
  def parse_usage_ping_keys(object, key_path = [])
    if object.is_a?(Hash) && !object_with_schema?(key_path.join('.'))
      object.each_with_object([]) do |(key, value), result|
        result.append parse_usage_ping_keys(value, key_path + [key])
      end
    else
      key_path.join('.')
    end
  end

  def object_with_schema?(key_path)
    metric_files_with_schema.key?(key_path)
  end

  before do
    allow(Gitlab::UsageData).to receive_messages(count: -1, distinct_count: -1, estimate_batch_distinct_count: -1, sum: -1)
    allow(Gitlab::UsageData).to receive(:alt_usage_data).and_wrap_original do |m, *args, **kwargs|
      kwargs[:fallback] || Gitlab::Utils::UsageData::FALLBACK
    end
    allow(Gitlab::Geo).to receive(:enabled?).and_return(true)
    stub_licensed_features(requirements: true)
    stub_prometheus_queries
    stub_usage_data_connections
  end

  it 'is included in the Usage Ping hash structure', :aggregate_failures do
    msg = "see https://docs.gitlab.com/ee/development/service_ping/metrics_dictionary.html#metrics-added-dynamic-to-service-ping-payload"
    expect(metric_files_key_paths + events_not_defined_yet).to match_array(usage_ping_key_paths)
    expect(metric_files_key_paths + events_not_defined_yet).to match_array(usage_ping_key_paths), msg
  end

  describe 'metrics classes' do
    let(:parent_metric_classes) do
      [
        Gitlab::Usage::Metrics::Instrumentations::BaseMetric,
        Gitlab::Usage::Metrics::Instrumentations::GenericMetric,
        Gitlab::Usage::Metrics::Instrumentations::DatabaseMetric,
        Gitlab::Usage::Metrics::Instrumentations::RedisMetric,
        Gitlab::Usage::Metrics::Instrumentations::RedisHLLMetric,
        Gitlab::Usage::Metrics::Instrumentations::NumbersMetric
      ]
    end

    let(:ignored_classes) do
      [
        Gitlab::Usage::Metrics::Instrumentations::IssuesWithAlertManagementAlertsMetric,
        Gitlab::Usage::Metrics::Instrumentations::IssuesWithPrometheusAlertEvents,
        Gitlab::Usage::Metrics::Instrumentations::IssuesWithSelfManagedPrometheusAlertEvents
      ].freeze
    end

    def assert_uses_all_nested_classes(parent_module)
      parent_module.constants(false).each do |const_name|
        constant = parent_module.const_get(const_name, false)
        next if parent_metric_classes.include?(constant) || ignored_classes.include?(constant)

        if constant.is_a? Class
          metric_class_instance = instance_double(constant)
          expect(constant).to receive(:new).at_least(:once).and_return(metric_class_instance)
          allow(metric_class_instance).to receive(:available?).and_return(true)
          allow(metric_class_instance).to receive(:value).and_return(-1)
          expect(metric_class_instance).to receive(:value).at_least(:once)
        elsif constant.is_a? Module
          assert_uses_all_nested_classes(constant)
        end
      end
    end

    it 'uses all metrics classes' do
      assert_uses_all_nested_classes(Gitlab::Usage::Metrics::Instrumentations)
      usage_ping
    end
  end

  context 'with value json schema' do
    it 'has a valid structure', :aggregate_failures do
      metric_files_with_schema.each do |key_path, metric|
        structure = usage_ping.dig(*key_path.split('.').map(&:to_sym))

        expect(structure).to match_metric_definition_schema(metric.value_json_schema)
      end
    end
  end
end
