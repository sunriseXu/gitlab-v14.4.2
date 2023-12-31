# frozen_string_literal: true

module API
  module Entities
    class Commit < Grape::Entity
      expose :id, :short_id, :created_at
      expose :parent_ids
      expose :full_title, as: :title
      expose :safe_message, as: :message
      expose :author_name, :author_email, :authored_date
      expose :committer_name, :committer_email, :committed_date
      expose :trailers

      expose :web_url do |commit, _options|
        c = commit
        c = c.__subject__ if c.is_a?(Gitlab::View::Presenter::Base)
        Gitlab::UrlBuilder.build(c)
      end
    end
  end
end
