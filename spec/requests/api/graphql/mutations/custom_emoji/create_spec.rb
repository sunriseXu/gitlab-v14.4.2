# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new Custom Emoji' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:attributes) do
    {
      name: 'my_new_emoji',
      url: 'https://example.com/image.png',
      group_path: group.full_path
    }
  end

  let(:mutation) do
    graphql_mutation(:create_custom_emoji, attributes)
  end

  context 'when the user has no permission' do
    it 'does not create custom emoji' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(CustomEmoji, :count)
    end
  end

  context 'when user has permission' do
    before do
      group.add_developer(current_user)
    end

    it 'creates custom emoji' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(CustomEmoji, :count).by(1)

      gql_response = graphql_mutation_response(:create_custom_emoji)
      expect(gql_response['errors']).to eq([])
      expect(gql_response['customEmoji']['name']).to eq(attributes[:name])
      expect(gql_response['customEmoji']['url']).to eq(attributes[:url])
    end

    context 'when the custom_emoji feature flag is disabled' do
      before do
        stub_feature_flags(custom_emoji: false)
      end

      it 'does nothing and returns and error' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to not_change(CustomEmoji, :count)

        expect_graphql_errors_to_include('Custom emoji feature is disabled')
      end
    end
  end
end
