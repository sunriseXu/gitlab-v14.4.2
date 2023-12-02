# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PersonalAccessTokensController do
  let(:user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  before do
    sign_in(user)
  end

  describe '#create' do
    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    it "allows creation of a token with scopes" do
      name = 'My PAT'
      scopes = %w[api read_user]

      post :create, params: { personal_access_token: token_attributes.merge(scopes: scopes, name: name) }

      expect(created_token).not_to be_nil
      expect(created_token.name).to eq(name)
      expect(created_token.scopes).to eq(scopes)
      expect(PersonalAccessToken.active).to include(created_token)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now.to_date

      post :create, params: { personal_access_token: token_attributes.merge(expires_at: expires_at) }

      expect(created_token).not_to be_nil
      expect(created_token.expires_at).to eq(expires_at)
    end
  end

  describe '#index' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }

    before do
      # Impersonation and inactive personal tokens are ignored
      create(:personal_access_token, :impersonation, user: user)
      create(:personal_access_token, :revoked, user: user)
      get :index
    end

    it "only includes details of the active personal access token" do
      active_personal_access_tokens_detail =
        ::PersonalAccessTokenSerializer.new.represent([active_personal_access_token])

      expect(assigns(:active_personal_access_tokens).to_json).to eq(active_personal_access_tokens_detail.to_json)
    end

    it "sets PAT name and scopes" do
      name = 'My PAT'
      scopes = 'api,read_user'

      get :index, params: { name: name, scopes: scopes }

      expect(assigns(:personal_access_token)).to have_attributes(
        name: eq(name),
        scopes: contain_exactly(:api, :read_user)
      )
    end

    context "access_token_pagination feature flag is enabled" do
      before do
        stub_feature_flags(access_token_pagination: true)
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
        create(:personal_access_token, user: user)
      end

      it "returns paginated response" do
        get :index, params: { page: 1 }
        expect(assigns(:active_personal_access_tokens).count).to eq(1)
      end

      it 'adds appropriate headers' do
        get :index, params: { page: 1 }
        expect_header('X-Per-Page', '1')
        expect_header('X-Page', '1')
        expect_header('X-Next-Page', '2')
        expect_header('X-Total', '2')
      end
    end

    context "tokens returned are ordered" do
      let(:expires_1_day_from_now) { 1.day.from_now.to_date }
      let(:expires_2_day_from_now) { 2.days.from_now.to_date }

      before do
        create(:personal_access_token, user: user, name: "Token1", expires_at: expires_1_day_from_now)
        create(:personal_access_token, user: user, name: "Token2", expires_at: expires_2_day_from_now)
      end

      it "orders token list ascending on expires_at" do
        get :index

        first_token = assigns(:active_personal_access_tokens).first.as_json
        expect(first_token['name']).to eq("Token1")
        expect(first_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))
      end

      it "orders tokens on id in case token has same expires_at" do
        create(:personal_access_token, user: user, name: "Token3", expires_at: expires_1_day_from_now)

        get :index

        first_token = assigns(:active_personal_access_tokens).first.as_json
        expect(first_token['name']).to eq("Token3")
        expect(first_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))

        second_token = assigns(:active_personal_access_tokens).second.as_json
        expect(second_token['name']).to eq("Token1")
        expect(second_token['expires_at']).to eq(expires_1_day_from_now.strftime("%Y-%m-%d"))
      end
    end

    context "access_token_pagination feature flag is disabled" do
      before do
        stub_feature_flags(access_token_pagination: false)
        create(:personal_access_token, user: user)
      end

      it "returns all tokens in system" do
        get :index, params: { page: 1 }
        expect(assigns(:active_personal_access_tokens).count).to eq(2)
      end
    end
  end

  def expect_header(header_name, header_val)
    expect(response.headers[header_name]).to eq(header_val)
  end
end
