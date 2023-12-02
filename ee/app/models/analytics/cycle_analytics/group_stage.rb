# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupStage < ApplicationRecord
      include Analytics::CycleAnalytics::Stage
      include DatabaseEventTracking

      validates :group, presence: true
      validates :name, uniqueness: { scope: [:group_id, :group_value_stream_id] }
      belongs_to :group
      belongs_to :value_stream, class_name: 'Analytics::CycleAnalytics::GroupValueStream', foreign_key: :group_value_stream_id

      alias_attribute :parent, :group
      alias_attribute :parent_id, :group_id

      alias_attribute :value_stream_id, :group_value_stream_id

      def self.relative_positioning_query_base(stage)
        where(group_id: stage.group_id)
      end

      def self.relative_positioning_parent_column
        :group_id
      end

      def self.distinct_stages_within_hierarchy(group)
        with_preloaded_labels
          .where(group_id: group.self_and_descendants.select(:id))
          .select("DISTINCT ON(stage_event_hash_id) #{quoted_table_name}.*")
      end

      SNOWPLOW_ATTRIBUTES = %i[
        id
        created_at
        updated_at
        relative_position
        start_event_identifier
        end_event_identifier
        group_id
        start_event_label_id
        end_event_label_id
        hidden
        custom
        name
        group_value_stream_id
      ].freeze
    end
  end
end
