# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectReplicator do
  let(:model_record) { build(:lfs_object, :with_file) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
