# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Representation
      class ProtectedBranch
        include ToHash
        include ExposeAttribute

        attr_reader :attributes

        expose_attribute :id, :allow_force_pushes

        # Builds a Branch Protection info from a GitHub API response.
        # Resource structure details:
        # https://docs.github.com/en/rest/branches/branch-protection#get-branch-protection
        # branch_protection - An instance of `Sawyer::Resource` containing the protection details.
        def self.from_api_response(branch_protection, _additional_object_data = {})
          branch_name = branch_protection.url.match(%r{/branches/(\S{1,255})/protection$})[1]

          hash = {
            id: branch_name,
            allow_force_pushes: branch_protection.allow_force_pushes.enabled
          }

          new(hash)
        end

        # Builds a new Protection using a Hash that was built from a JSON payload.
        def self.from_json_hash(raw_hash)
          new(Representation.symbolize_hash(raw_hash))
        end

        # attributes - A Hash containing the raw Protection details. The keys of this
        #              Hash (and any nested hashes) must be symbols.
        def initialize(attributes)
          @attributes = attributes
        end

        def github_identifiers
          { id: id }
        end
      end
    end
  end
end
