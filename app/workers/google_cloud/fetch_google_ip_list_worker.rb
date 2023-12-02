# frozen_string_literal: true

module GoogleCloud
  class FetchGoogleIpListWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :build_artifacts
    urgency :low
    deduplicate :until_executing
    idempotent!

    def perform
      GoogleCloud::FetchGoogleIpListService.new.execute
    end
  end
end
