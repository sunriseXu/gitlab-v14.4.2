# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe '#satisfied_by?' do
    let(:context) { instance_double(Gitlab::Ci::Build::Context::Base) }

    subject(:satisfied_by) { described_class.new(globs).satisfied_by?(pipeline, context) }

    context 'a glob matching rule' do
      using RSpec::Parameterized::TableSyntax

      let(:pipeline) { build(:ci_pipeline) }
      let(:context) {}

      before do
        allow(pipeline).to receive(:modified_paths).and_return(files.keys)
      end

      # rubocop:disable Layout/LineLength
      where(:case_name, :globs, :files, :satisfied) do
        'exact top-level match'      | { paths: ['Dockerfile'] }               | { 'Dockerfile' => '', 'Gemfile' => '' }            | true
        'exact top-level no match'   | { paths: ['Dockerfile'] }               | { 'Gemfile' => '' }                                | false
        'pattern top-level match'    | { paths: ['Docker*'] }                  | { 'Dockerfile' => '', 'Gemfile' => '' }            | true
        'pattern top-level no match' | { paths: ['Docker*'] }                  | { 'Gemfile' => '' }                                | false
        'exact nested match'         | { paths: ['project/build.properties'] } | { 'project/build.properties' => '' }               | true
        'exact nested no match'      | { paths: ['project/build.properties'] } | { 'project/README.md' => '' }                      | false
        'pattern nested match'       | { paths: ['src/**/*.go'] }              | { 'src/gitlab.com/goproject/goproject.go' => '' }  | true
        'pattern nested no match'    | { paths: ['src/**/*.go'] }              | { 'src/gitlab.com/goproject/README.md' => '' }     | false
        'ext top-level match'        | { paths: ['*.go'] }                     | { 'main.go' => '', 'cmd/goproject/main.go' => '' } | true
        'ext nested no match'        | { paths: ['*.go'] }                     | { 'cmd/goproject/main.go' => '' }                  | false
        'ext slash no match'         | { paths: ['/*.go'] }                    | { 'main.go' => '', 'cmd/goproject/main.go' => '' } | false
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to eq(satisfied) }
      end
    end

    context 'when pipeline is nil' do
      let(:pipeline) {}
      let(:context) {}
      let(:globs) { { paths: [] } }

      it { is_expected.to be_truthy }
    end

    context 'when using variable expansion' do
      let(:pipeline) { build(:ci_pipeline) }
      let(:modified_paths) { ['helm/test.txt'] }
      let(:globs) { { paths: ['$HELM_DIR/**/*'] } }
      let(:context) { instance_double(Gitlab::Ci::Build::Context::Base) }

      before do
        allow(pipeline).to receive(:modified_paths).and_return(modified_paths)
      end

      context 'when context is nil' do
        let(:context) {}

        it { is_expected.to be_falsey }
      end

      context 'when modified paths are nil' do
        let(:modified_paths) {}

        it { is_expected.to be_truthy }
      end

      context 'when context has the specified variables' do
        let(:variables_hash) do
          { 'HELM_DIR' => 'helm' }
        end

        before do
          allow(context).to receive(:variables_hash).and_return(variables_hash)
        end

        it { is_expected.to be_truthy }
      end

      context 'when variable expansion does not match' do
        let(:globs) { { paths: ['path/with/$in/it/*'] } }
        let(:modified_paths) { ['path/with/$in/it/file.txt'] }

        before do
          allow(context).to receive(:variables_hash).and_return({})
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when using compare_to' do
      let_it_be(:project) do
        create(:project, :custom_repo,
               files: { 'README.md' => 'readme' })
      end

      let_it_be(:user) { project.owner }

      before_all do
        project.repository.add_branch(user, 'feature_1', 'master')

        project.repository.create_file(
          user, 'file1.txt', 'file 1', message: 'Create file1.txt', branch_name: 'feature_1'
        )
        project.repository.add_tag(user, 'tag_1', 'feature_1')

        project.repository.create_file(
          user, 'file2.txt', 'file 2', message: 'Create file2.txt', branch_name: 'feature_1'
        )
        project.repository.add_branch(user, 'feature_2', 'feature_1')

        project.repository.update_file(
          user, 'file2.txt', 'file 2 updated', message: 'Update file2.txt', branch_name: 'feature_2'
        )
      end

      context 'when compare_to is branch or tag' do
        using RSpec::Parameterized::TableSyntax

        where(:pipeline_ref, :compare_to, :paths, :ff, :result) do
          'feature_1' | 'master'    | ['file1.txt'] | true  | true
          'feature_1' | 'master'    | ['README.md'] | true  | false
          'feature_1' | 'master'    | ['xyz.md']    | true  | false
          'feature_2' | 'master'    | ['file1.txt'] | true  | true
          'feature_2' | 'master'    | ['file2.txt'] | true  | true
          'feature_2' | 'feature_1' | ['file1.txt'] | true  | false
          'feature_2' | 'feature_1' | ['file1.txt'] | false | true
          'feature_2' | 'feature_1' | ['file2.txt'] | true  | true
          'feature_1' | 'tag_1'     | ['file1.txt'] | true  | false
          'feature_1' | 'tag_1'     | ['file1.txt'] | false | true
          'feature_1' | 'tag_1'     | ['file2.txt'] | true  | true
          'feature_2' | 'tag_1'     | ['file2.txt'] | true  | true
        end

        with_them do
          let(:globs) { { paths: paths, compare_to: compare_to } }

          let(:pipeline) do
            build(:ci_pipeline, project: project, ref: pipeline_ref, sha: project.commit(pipeline_ref).sha)
          end

          before do
            stub_feature_flags(ci_rules_changes_compare: ff)
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when compare_to is a sha' do
        let(:globs) { { paths: ['file2.txt'], compare_to: project.commit('tag_1').sha } }

        let(:pipeline) do
          build(:ci_pipeline, project: project, ref: 'feature_2', sha: project.commit('feature_2').sha)
        end

        it { is_expected.to be_truthy }
      end

      context 'when compare_to is not a valid ref' do
        let(:globs) { { paths: ['file1.txt'], compare_to: 'xyz' } }

        let(:pipeline) do
          build(:ci_pipeline, project: project, ref: 'feature_2', sha: project.commit('feature_2').sha)
        end

        it 'raises ParseError' do
          expect { satisfied_by }.to raise_error(
            ::Gitlab::Ci::Build::Rules::Rule::Clause::ParseError, 'rules:changes:compare_to is not a valid ref'
          )
        end

        context 'when the FF ci_rules_changes_compare is disabled' do
          before do
            stub_feature_flags(ci_rules_changes_compare: false)
          end

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
