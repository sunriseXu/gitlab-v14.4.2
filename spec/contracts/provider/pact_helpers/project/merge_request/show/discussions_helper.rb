# frozen_string_literal: true

require_relative '../../../../spec_helper'
require_relative '../../../../states/project/merge_request/show_state'

module Provider
  module DiscussionsHelper
    Pact.service_provider "Merge Request Discussions Endpoint" do
      app { Environments::Test.app }

      honours_pact_with 'MergeRequest#show' do
        pact_uri '../contracts/project/merge_request/show/mergerequest#show-merge_request_discussions_endpoint.json'
      end
    end
  end
end
