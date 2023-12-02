# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'danger'
require 'danger/plugins/internal/helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/config_files'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ConfigFiles do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:matching_line) { "+ introduced_by_url:" }

  subject(:config_file) { fake_danger.new(helper: fake_helper) }

  before do
    allow(config_file).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#add_suggestion_for_missing_introduced_by_url' do
    let(:file_lines) do
      [
        "---",
        "name: about_your_company_registration_flow",
        "introduced_by_url: #{url}",
        "rollout_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/355909",
        "milestone: '14.10'"
      ]
    end

    let(:filename) { 'config/feature_flags/new_ff.yml' }

    before do
      allow(config_file.project_helper).to receive(:file_lines).and_return(file_lines)
      allow(config_file.helper).to receive(:added_files).and_return([filename])
      allow(config_file.helper).to receive(:mr_web_url).and_return(url)
    end

    context 'when config file has an empty introduced_by_url line' do
      let(:url) { '' }

      it 'adds suggestions at the correct line' do
        expected_format = format(described_class::SUGGEST_INTRODUCED_BY_COMMENT, url: url)
        expect(config_file).to receive(:markdown).with(expected_format, file: filename, line: 3)

        config_file.add_suggestion_for_missing_introduced_by_url
      end
    end

    context 'when config file has an introduced_by_url line with value' do
      let(:url) { 'https://gitlab.com/gitlab-org/gitlab/-/issues/1' }

      it 'does not add suggestion' do
        expect(config_file).not_to receive(:markdown)

        config_file.add_suggestion_for_missing_introduced_by_url
      end
    end
  end

  describe '#new_config_files' do
    let(:expected_files) do
      %w[
        config/feature_flags/first.yml
        config/events/1234_new_event.yml
        config/metrics/count_7d/new_metric.yml
      ]
    end

    before do
      all_new_files = %w[
        app/workers/a.rb
        doc/events/new_event.md
        config/feature_flags/first.yml
        config/events/1234_new_event.yml
        config/metrics/count_7d/new_metric.yml
        app/assets/index.js
      ]

      allow(config_file.helper).to receive(:added_files).and_return(all_new_files)
    end

    it 'returns added, modified, and renamed_after files by default' do
      expect(config_file.new_config_files).to match_array(expected_files)
    end
  end
end
