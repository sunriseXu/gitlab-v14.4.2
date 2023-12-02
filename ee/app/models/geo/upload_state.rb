# frozen_string_literal: true

module Geo
  class UploadState < ApplicationRecord
    include ::Geo::VerificationStateDefinition
    include EachBatch

    self.primary_key = :upload_id

    belongs_to :upload, inverse_of: :upload_state

    validates :verification_failure, length: { maximum: 255 }
    validates :verification_state, :upload, presence: true
  end
end
