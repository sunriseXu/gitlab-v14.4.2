# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy do
  describe 'cicd runners' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    subject(:policy) { described_class.new(user, runner) }

    context 'with auditor access' do
      let_it_be(:user) { create(:auditor) }
      let_it_be(:instance_runner) { create(:ci_runner, :instance) }
      let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
      let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

      context 'when auditor_group_runner_access FF disabled' do
        before do
          stub_feature_flags(auditor_group_runner_access: false)
        end

        context 'with instance runner' do
          let(:runner) { instance_runner }

          it 'disallows all permissions' do
            expect_disallowed :read_runner, :assign_runner, :update_runner, :delete_runner
          end
        end

        context 'with group runner' do
          let(:runner) { group_runner }

          it 'disallows all permissions' do
            expect_disallowed :read_runner, :assign_runner, :update_runner, :delete_runner
          end
        end

        context 'with project runner' do
          let(:runner) { project_runner }

          it 'disallows all permissions' do
            expect_disallowed :read_runner, :assign_runner, :update_runner, :delete_runner
          end
        end
      end

      context 'when auditor_group_runner_access FF enabled' do
        before do
          stub_feature_flags(auditor_group_runner_access: true)
        end

        context 'with instance runner' do
          let(:runner) { instance_runner }

          it 'disallows all permissions' do
            expect_disallowed :read_runner, :assign_runner, :update_runner, :delete_runner
          end
        end

        context 'with group runner' do
          let(:runner) { group_runner }

          it 'allows only read permissions' do
            expect_allowed :read_runner
            expect_disallowed :assign_runner, :update_runner, :delete_runner
          end
        end

        context 'with project runner' do
          let(:runner) { project_runner }

          it 'allows only read permissions' do
            expect_allowed :read_runner
            expect_disallowed :assign_runner, :update_runner, :delete_runner
          end
        end
      end
    end
  end
end
