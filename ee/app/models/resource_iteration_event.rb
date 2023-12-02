# frozen_string_literal: true

class ResourceIterationEvent < ResourceTimeboxEvent
  include EachBatch

  belongs_to :iteration

  scope :with_api_entity_associations, -> { preload(:iteration, :user) }
  scope :by_user, -> (user) { where(user_id: user ) }
end
