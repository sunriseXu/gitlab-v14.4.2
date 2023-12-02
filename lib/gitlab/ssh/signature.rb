# frozen_string_literal: true

# Signature verification with ed25519 keys
# requires this gem to be loaded.
require 'ed25519'

module Gitlab
  module Ssh
    class Signature
      include Gitlab::Utils::StrongMemoize

      def initialize(signature_text, signed_text, committer_email)
        @signature_text = signature_text
        @signed_text = signed_text
        @committer_email = committer_email
      end

      def verification_status
        strong_memoize(:verification_status) do
          next :unverified unless all_attributes_present?
          next :unverified unless valid_signature_blob? && committer
          next :unknown_key unless signed_by_key
          next :other_user unless signed_by_key.user == committer

          :verified
        end
      end

      def signed_by_key
        strong_memoize(:signed_by_key) do
          next unless key_fingerprint

          Key.find_by_fingerprint_sha256(key_fingerprint)
        end
      end

      private

      def all_attributes_present?
        # Signing an empty string is valid, but signature_text and committer_email
        # must be non-empty.
        @signed_text && @signature_text.present? && @committer_email.present?
      end

      # Verifies the signature using the public key embedded in the blob.
      # This proves that the signed_text was signed by the private key
      # of the public key identified by `key_fingerprint`. Afterwards, we
      # still need to check that the key belongs to the committer.
      def valid_signature_blob?
        return false unless signature

        signature.verify(@signed_text)
      end

      def committer
        # Lookup by email because users can push verified commits that were made
        # by someone else. For example: Doing a rebase.
        strong_memoize(:committer) { User.find_by_any_email(@committer_email, confirmed: true) }
      end

      def signature
        strong_memoize(:signature) do
          ::SSHData::Signature.parse_pem(@signature_text)
        rescue SSHData::DecodeError
          nil
        end
      end

      def key_fingerprint
        strong_memoize(:key_fingerprint) { signature&.public_key&.fingerprint }
      end
    end
  end
end
