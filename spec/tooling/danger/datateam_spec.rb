# frozen_string_literal: true

require 'rspec-parameterized'
require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'
require 'pry'
require_relative '../../../tooling/danger/datateam'

RSpec.describe Tooling::Danger::Datateam do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:datateam) { fake_danger.new(helper: fake_helper) }

  describe 'data team danger' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        'with structure.sql changes and no Data Warehouse::Impact Check label' => {
          modified_files: %w(db/structure.sql app/models/user.rb),
          changed_lines: ['+group_id bigint NOT NULL'],
          mr_labels: [],
          impacted: true,
          impacted_files: %w(db/structure.sql)
        },
        'with structure.sql changes and Data Warehouse::Impact Check label' => {
          modified_files: %w(db/structure.sql),
          changed_lines: ['+group_id bigint NOT NULL)'],
          mr_labels: ['Data Warehouse::Impact Check'],
          impacted: false,
          impacted_files: %w(db/structure.sql)
        },
        'with user model changes' => {
          modified_files: %w(app/models/users.rb),
          changed_lines: ['+has_one :namespace'],
          mr_labels: [],
          impacted: false,
          impacted_files: []
        },
        'with perfomance indicator changes and no Data Warehouse::Impact Check label' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+-gmau'],
          mr_labels: [],
          impacted: true,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with perfomance indicator changes and Data Warehouse::Impact Check label' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml),
          changed_lines: ['+-gmau'],
          mr_labels: ['Data Warehouse::Impact Check'],
          impacted: false,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with metric file changes and no performance indicator changes' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml),
          changed_lines: ['-product_stage: growth'],
          mr_labels: [],
          impacted: false,
          impacted_files: []
        },
        'with metric file changes and no performance indicator changes and other label' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml),
          changed_lines: ['-product_stage: growth'],
          mr_labels: ['type::maintenance'],
          impacted: false,
          impacted_files: []
        },
        'with performance indicator changes and other label' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+-gmau'],
          mr_labels: ['type::maintenance'],
          impacted: true,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with performance indicator changes, Data Warehouse::Impact Check and other label' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+-gmau'],
          mr_labels: ['type::maintenance', 'Data Warehouse::Impact Check'],
          impacted: false,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with performance indicator changes and other labels' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+-gmau'],
          mr_labels: ['type::maintenance', 'Data Warehouse::Impacted'],
          impacted: false,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with metric status removed' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+status: removed'],
          mr_labels: ['type::maintenance'],
          impacted: true,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        },
        'with metric status active' => {
          modified_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb),
          changed_lines: ['+status: active'],
          mr_labels: ['type::maintenance'],
          impacted: false,
          impacted_files: %w(config/metrics/20210216182127_user_secret_detection_jobs.yml)
        }
      }
    end

    with_them do
      before do
        allow(fake_helper).to receive(:modified_files).and_return(modified_files)
        allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
        allow(fake_helper).to receive(:mr_labels).and_return(mr_labels)
        allow(fake_helper).to receive(:markdown_list).with(impacted_files).and_return(impacted_files.map { |item| "* `#{item}`" }.join("\n"))
      end

      it :aggregate_failures do
        expect(datateam.impacted?).to be(impacted)
        expect(datateam.build_message).to match_expected_message
      end
    end
  end

  def match_expected_message
    return be_nil unless impacted

    start_with(described_class::CHANGED_SCHEMA_MESSAGE).and(include(*impacted_files))
  end
end
