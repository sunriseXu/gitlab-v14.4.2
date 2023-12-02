# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class BaseDoraSummary
          include Gitlab::CycleAnalytics::Summary::Defaults

          def initialize(stage:, current_user:, options:)
            @stage = stage
            @current_user = current_user
            @options = options
            @from = options[:from].to_date
            @to = (options[:to] || Date.today).to_date
          end

          def value
            @value ||= begin
              metric = dora_metric

              # nil signals the summary class to not even try to serialize the result
              metric[:status] == :success ? convert_to_days(metric[:data]) : nil
            end
          end

          def unit
            n_('day', 'days', value)
          end

          private

          attr_reader :stage, :current_user, :options, :from, :to

          def metric_key
            raise NoMethodError, 'metric_key must be overloaded in child class'
          end

          def dora_metric
            params = {
              start_date: from,
              end_date: to,
              interval: 'all',
              environment_tiers: %w[production],
              metric: metric_key
            }

            params[:group_project_ids] = options[:projects] if options[:projects].present?

            Dora::AggregateMetricsService.new(
              container: stage.parent,
              current_user: current_user,
              params: params
            ).execute
          end

          def convert_to_days(seconds)
            return Gitlab::CycleAnalytics::Summary::Value::None.new if seconds.to_i == 0

            days = seconds.fdiv(1.day).round(1)

            Gitlab::CycleAnalytics::Summary::Value::Numeric.new(days)
          end
        end
      end
    end
  end
end
