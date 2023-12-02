# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class AllureMetadataFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Support::InfluxdbTools

        ::RSpec::Core::Formatters.register(
          self,
          :start,
          :example_finished
        )

        # Starts test run
        # Fetch flakiness data in mr pipelines to help identify unrelated flaky failures
        #
        # @param [RSpec::Core::Notifications::StartNotification] _start_notification
        # @return [void]
        def start(_start_notification)
          return unless merge_request_iid # on main runs allure native history has pass rate already

          save_flaky_specs
          log(:debug, "Fetched #{flaky_specs.length} flaky testcases!")
        rescue StandardError => e
          log(:error, "Failed to fetch flaky spec data for report: #{e}")
          @flaky_specs = {}
        end

        # Finished example
        # Add additional metadata to report
        #
        # @param [RSpec::Core::Notifications::ExampleNotification] example_notification
        # @return [void]
        def example_finished(example_notification)
          example = example_notification.example

          add_quarantine_issue_link(example)
          add_failure_issues_link(example)
          add_ci_job_link(example)
          set_flaky_status(example)
        end

        private

        # Add quarantine issue links
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_quarantine_issue_link(example)
          issue_link = example.metadata.dig(:quarantine, :issue)

          return unless issue_link
          return example.issue('Quarantine issue', issue_link) if issue_link.is_a?(String)
          return issue_link.each { |link| example.issue('Quarantine issue', link) } if issue_link.is_a?(Array)
        rescue StandardError => e
          log(:error, "Failed to add quarantine issue linkt for example '#{example.description}', error: #{e}")
        end

        # Add failure issues link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_failure_issues_link(example)
          spec_file = example.file_path.split('/').last
          example.issue(
            'Failure issues',
            "https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=#{spec_file}"
          )
        rescue StandardError => e
          log(:error, "Failed to add failure issue link for example '#{example.description}', error: #{e}")
        end

        # Add ci job link
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def add_ci_job_link(example)
          return unless Runtime::Env.running_in_ci?

          example.add_link(name: "Job(#{Runtime::Env.ci_job_name})", url: Runtime::Env.ci_job_url)
        rescue StandardError => e
          log(:error, "Failed to add failure issue link for example '#{example.description}', error: #{e}")
        end

        # Mark test as flaky
        #
        # @param [RSpec::Core::Example] example
        # @return [void]
        def set_flaky_status(example)
          return unless merge_request_iid && flaky_specs.key?(example.metadata[:testcase])

          example.set_flaky
          example.parameter("pass_rate", "#{flaky_specs[example.metadata[:testcase]].round(1)}%")
          log(:debug, "Setting spec as flaky because it's pass rate is below 98%")
        rescue StandardError => e
          log(:error, "Failed to add spec pass rate data for example '#{example.description}', error: #{e}")
        end

        # Flaky specs with pass rate below 98%
        #
        # @return [Array]
        def flaky_specs
          @flaky_specs ||= influx_data.lazy.each_with_object({}) do |data, result|
            # Do not consider failures in same merge request
            records = data.records.reject { |r| r.values["_value"] == merge_request_iid }

            runs = records.count
            failed = records.count { |r| r.values["status"] == "failed" }
            pass_rate = 100 - ((failed.to_f / runs.to_f) * 100)

            # Consider spec with a pass rate less than 98% as flaky
            result[records.last.values["testcase"]] = pass_rate if pass_rate < 98
          end.compact
        end

        alias_method :save_flaky_specs, :flaky_specs

        # Records of previous failures for runs of same type
        #
        # @return [Array]
        def influx_data
          return [] unless run_type

          query_api.query(query: <<~QUERY).values
            from(bucket: "#{Support::InfluxdbTools::INFLUX_TEST_METRICS_BUCKET}")
              |> range(start: -14d)
              |> filter(fn: (r) => r._measurement == "test-stats")
              |> filter(fn: (r) => r.run_type == "#{run_type}" and
                r.status != "pending" and
                r.quarantined == "false" and
                r._field == "merge_request_iid"
              )
              |> group(columns: ["testcase"])
          QUERY
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[Allure]: #{message}")
        end
      end
    end
  end
end
