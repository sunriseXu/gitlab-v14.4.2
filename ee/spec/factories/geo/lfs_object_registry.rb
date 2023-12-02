# frozen_string_literal: true

FactoryBot.define do
  factory :geo_lfs_object_registry, class: 'Geo::LfsObjectRegistry' do
    association(:lfs_object, :with_file)
    state { Geo::LfsObjectRegistry.state_value(:pending) }

    trait :synced do
      state { Geo::LfsObjectRegistry.state_value(:synced) }
      last_synced_at { 5.days.ago }
    end

    trait :failed do
      state { Geo::LfsObjectRegistry.state_value(:failed) }
      last_synced_at { 1.day.ago }
      retry_count { 2 }
      last_sync_failure { 'Random error' }
    end

    trait :started do
      state { Geo::LfsObjectRegistry.state_value(:started) }
      last_synced_at { 1.day.ago }
      retry_count { 0 }
    end

    trait :verification_succeeded do
      verification_checksum { 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef' }
      verification_state { Geo::LfsObjectRegistry.verification_state_value(:verification_succeeded) }
      verified_at { 5.days.ago }
    end
  end
end
