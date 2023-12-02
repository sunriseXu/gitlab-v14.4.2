# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountFooMetric do
  let(:expected_value) { 1 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
end