# frozen_string_literal: true

class CreateSbomVulnerableComponentVersions < Gitlab::Database::Migration[2.0]
  ADVISORY_INDEX_NAME = "index_vulnerable_component_versions_on_vulnerability_advisory"
  SBOM_COMPONENT_INDEX_NAME = "index_vulnerable_component_versions_on_sbom_component_version"

  def change
    create_table :sbom_vulnerable_component_versions do |t|
      t.references :vulnerability_advisory,
                   index: { name: ADVISORY_INDEX_NAME }

      t.references :sbom_component_version,
                   index: { name: SBOM_COMPONENT_INDEX_NAME }

      t.timestamps_with_timezone null: false
    end
  end
end
