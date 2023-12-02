# frozen_string_literal: true

module EE
  module WorkItemsHelper
    extend ::Gitlab::Utils::Override

    override :work_items_index_data
    def work_items_index_data(project)
      super.merge(
        has_issue_weights_feature: project.licensed_feature_available?(:issue_weights).to_s
      )
    end
  end
end
