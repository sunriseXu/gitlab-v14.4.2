# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::CreateService do
  let_it_be_with_reload(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:params) do
    {
      name: name,
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    let(:name) { 'master' }

    it 'creates a new protected branch' do
      expect { service.execute }.to change(ProtectedBranch, :count).by(1)
      expect(project.protected_branches.last.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
      expect(project.protected_branches.last.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
    end

    it 'refreshes the cache' do
      expect_next_instance_of(ProtectedBranches::CacheService) do |cache_service|
        expect(cache_service).to receive(:refresh)
      end

      service.execute
    end

    context 'when protecting a branch with a name that contains HTML tags' do
      let(:name) { 'foo<b>bar<\b>' }

      it 'creates a new protected branch' do
        expect { service.execute }.to change(ProtectedBranch, :count).by(1)
        expect(project.protected_branches.last.name).to eq(name)
      end
    end

    context 'when user does not have permission' do
      let(:user) { create(:user) }

      before do
        project.add_developer(user)
      end

      it 'creates a new protected branch if we skip authorization step' do
        expect { service.execute(skip_authorization: true) }.to change(ProtectedBranch, :count).by(1)
      end

      it 'raises Gitlab::Access:AccessDeniedError' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when a policy restricts rule creation' do
      it "prevents creation of the protected branch rule" do
        disallow(:create_protected_branch, an_instance_of(ProtectedBranch))

        expect do
          service.execute
        end.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
