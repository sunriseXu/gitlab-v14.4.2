# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::DeploymentsMenu do
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  describe '#render?' do
    subject { described_class.new(context) }

    context 'when menu does not have any menu items' do
      it 'returns false' do
        allow(subject).to receive(:has_renderable_items?).and_return(false)

        expect(subject.render?).to be false
      end
    end

    context 'when menu has menu items' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end
  end

  describe 'Menu Items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    shared_examples 'access rights checks' do
      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end

      describe 'when the feature is disabled' do
        before do
          project.update_attribute("#{item_id}_access_level", 'disabled')
        end

        it { is_expected.to be_nil }
      end

      describe 'when split_operations_visibility_permissions FF is disabled' do
        before do
          stub_feature_flags(split_operations_visibility_permissions: false)
        end

        it { is_expected.not_to be_nil }

        context 'and the feature is disabled' do
          before do
            project.update_attribute("#{item_id}_access_level", 'disabled')
          end

          it { is_expected.not_to be_nil }
        end

        context 'and operations is disabled' do
          before do
            project.update_attribute(:operations_access_level, 'disabled')
          end

          it do
            is_expected.to be_nil if [:environments, :feature_flags].include?(item_id)
          end
        end
      end
    end

    describe 'Feature Flags' do
      let(:item_id) { :feature_flags }

      it_behaves_like 'access rights checks'
    end

    describe 'Environments' do
      let(:item_id) { :environments }

      it_behaves_like 'access rights checks'
    end

    describe 'Releases' do
      let(:item_id) { :releases }

      it_behaves_like 'access rights checks'
    end
  end
end
