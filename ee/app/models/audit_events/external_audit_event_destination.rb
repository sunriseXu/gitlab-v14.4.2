# frozen_string_literal: true

module AuditEvents
  class ExternalAuditEventDestination < ApplicationRecord
    include Limitable

    STREAMING_TOKEN_HEADER_KEY = "X-Gitlab-Event-Streaming-Token"
    MAXIMUM_HEADER_COUNT = 20

    self.limit_name = 'external_audit_event_destinations'
    self.limit_scope = :group
    self.table_name = 'audit_events_external_audit_event_destinations'

    belongs_to :group, class_name: '::Group', foreign_key: 'namespace_id'
    has_many :headers,
             class_name: 'AuditEvents::Streaming::Header'

    validates :destination_url, public_url: true, presence: true
    validates :destination_url, uniqueness: { scope: :namespace_id }, length: { maximum: 255 }
    validates :verification_token, length: { in: 16..24 }, allow_nil: true
    validates :verification_token, presence: true, on: :update

    has_secure_token :verification_token, length: 24

    validate :has_fewer_than_20_headers?
    validate :root_level_group?

    def headers_hash
      { STREAMING_TOKEN_HEADER_KEY => verification_token }.merge(headers.map(&:to_hash).inject(:merge).to_h)
    end

    private

    def has_fewer_than_20_headers?
      if headers.count > MAXIMUM_HEADER_COUNT
        errors.add(:headers, "are limited to #{MAXIMUM_HEADER_COUNT} per destination")
      end
    end

    def root_level_group?
      errors.add(:group, 'must not be a subgroup') if group.subgroup?
    end
  end
end
