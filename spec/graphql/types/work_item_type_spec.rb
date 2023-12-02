# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItem'] do
  specify { expect(described_class.graphql_name).to eq('WorkItem') }

  specify { expect(described_class).to require_graphql_authorizations(:read_work_item) }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::WorkItem) }

  it 'has specific fields' do
    fields = %i[
      confidential
      description
      description_html
      id
      iid
      lock_version
      project
      state title
      title_html
      userPermissions
      widgets
      work_item_type
      created_at
      updated_at
      closed_at
    ]

    expect(described_class).to have_graphql_fields(*fields)
  end
end
