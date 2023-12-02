export const MOCK_NEW_NODE_URL = 'http://localhost:3000/admin/geo/sites/new';

export const MOCK_EMPTY_STATE_SVG = 'illustrations/empty-state/geo-empty.svg';

export const MOCK_PRIMARY_VERSION = {
  version: '10.4.0-pre',
  revision: 'b93c51849b',
};

export const MOCK_REPLICABLE_TYPES = [
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Repository',
    titlePlural: 'Repositories',
    name: 'repository',
    namePlural: 'repositories',
    customReplicationUrl: 'admin/geo/replication/projects',
  },
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Wiki',
    titlePlural: 'Wikis',
    name: 'wiki',
    namePlural: 'wikis',
    noReplicationView: true,
  },
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Design',
    titlePlural: 'Designs',
    name: 'design',
    namePlural: 'designs',
    customReplicationUrl: 'admin/geo/replication/designs',
  },
  {
    dataType: 'blob',
    dataTypeTitle: 'File',
    title: 'Package File',
    titlePlural: 'Package Files',
    name: 'package_file',
    namePlural: 'package_files',
  },
];

// This const is very specific, it is a hard coded filtered information from MOCK_NODES
// Be sure if updating you follow the pattern else getters_spec.js will fail.
export const MOCK_PRIMARY_VERIFICATION_INFO = [
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Repositories',
    values: {
      total: 12,
      success: 12,
      failed: 0,
    },
  },
];

// This const is very specific, it is a hard coded filtered information from MOCK_NODES
// Be sure if updating you follow the pattern else getters_spec.js will fail.
export const MOCK_SECONDARY_VERIFICATION_INFO = [
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Repositories',
    values: {
      total: 12,
      success: 0,
      failed: 12,
    },
  },
];

// This const is very specific, it is a hard coded filtered information from MOCK_NODES
// Be sure if updating you follow the pattern else getters_spec.js will fail.
export const MOCK_SECONDARY_SYNC_INFO = [
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Repositories',
    values: {
      total: 12,
      success: 12,
      failed: 0,
    },
  },
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Wikis',
    values: {
      total: 12,
      success: 6,
      failed: 6,
    },
  },
  {
    dataType: 'repository',
    dataTypeTitle: 'Git',
    title: 'Designs',
    values: {
      total: 12,
      success: 0,
      failed: 0,
    },
  },
  {
    dataType: 'blob',
    dataTypeTitle: 'File',
    title: 'Package Files',
    values: {
      total: 25,
      success: 25,
      failed: 0,
    },
  },
];

// This const is very specific, it is a hard coded camelCase version of MOCK_PRIMARY_NODE_RES and MOCK_PRIMARY_NODE_STATUSES_RES
// Be sure if updating you follow the pattern else actions_spec.js will fail.
export const MOCK_PRIMARY_NODE = {
  id: 1,
  name: 'Test Site 1',
  url: 'http://127.0.0.1:3001/',
  primary: true,
  enabled: true,
  current: true,
  geoNodeId: 1,
  healthStatus: 'Healthy',
  repositoriesCount: 12,
  repositoriesChecksumTotalCount: 12,
  repositoriesChecksummedCount: 12,
  repositoriesChecksumFailedCount: 0,
  replicationSlotsMaxRetainedWalBytes: 502658737,
  replicationSlotsCount: 1,
  replicationSlotsUsedCount: 0,
  version: '10.4.0-pre',
  revision: 'b93c51849b',
  webEditUrl: 'http://127.0.0.1:3001/admin/geo/sites/1',
};

// This const is very specific, it is a hard coded camelCase version of MOCK_SECONDARY_NODE_RES and MOCK_SECONDARY_NODE_STATUSES_RES
// Be sure if updating you follow the pattern else actions_spec.js will fail.
export const MOCK_SECONDARY_NODE = {
  id: 2,
  name: 'Test Site 2',
  url: 'http://127.0.0.1:3002/',
  primary: false,
  enabled: true,
  current: false,
  geoNodeId: 2,
  healthStatus: 'Healthy',
  repositoriesCount: 12,
  repositoriesFailedCount: 0,
  repositoriesSyncedCount: 12,
  repositoriesVerificationTotalCount: 12,
  repositoriesVerifiedCount: 0,
  repositoriesVerificationFailedCount: 12,
  wikisCount: 12,
  wikisFailedCount: 6,
  wikisSyncedCount: 6,
  designsCount: 12,
  designsFailedCount: 0,
  designsSyncedCount: 0,
  packageFilesCount: 25,
  packageFilesSyncedCount: 25,
  packageFilesFailedCount: 0,
  dbReplicationLagSeconds: 0,
  lastEventId: 3,
  lastEventTimestamp: 1511255200,
  cursorLastEventId: 3,
  cursorLastEventTimestamp: 1511255200,
  version: '10.4.0-pre',
  revision: 'b93c51849b',
  storageShardsMatch: true,
  webGeoProjectsUrl: 'http://127.0.0.1:3002/replication/projects',
  webGeoReplicationDetailsUrl: 'http://127.0.0.1:3002/admin/geo/sites/2/replication/lfs_objects',
};

export const MOCK_NODES = [MOCK_PRIMARY_NODE, MOCK_SECONDARY_NODE];

export const MOCK_PRIMARY_NODE_RES = {
  id: 1,
  name: 'Test Site 1',
  url: 'http://127.0.0.1:3001/',
  primary: true,
  enabled: true,
  current: true,
};

export const MOCK_SECONDARY_NODE_RES = {
  id: 2,
  name: 'Test Site 2',
  url: 'http://127.0.0.1:3002/',
  primary: false,
  enabled: true,
  current: false,
};

export const MOCK_NODES_RES = [MOCK_PRIMARY_NODE_RES, MOCK_SECONDARY_NODE_RES];

export const MOCK_PRIMARY_NODE_STATUSES_RES = {
  geo_node_id: 1,
  health_status: 'Healthy',
  repositories_count: 12,
  repositories_checksum_total_count: 12,
  repositories_checksummed_count: 12,
  repositories_checksum_failed_count: 0,
  replication_slots_max_retained_wal_bytes: 502658737,
  replication_slots_count: 1,
  replication_slots_used_count: 0,
  version: '10.4.0-pre',
  revision: 'b93c51849b',
  web_edit_url: 'http://127.0.0.1:3001/admin/geo/sites/1',
};

export const MOCK_SECONDARY_NODE_STATUSES_RES = {
  geo_node_id: 2,
  health_status: 'Healthy',
  repositories_count: 12,
  repositories_failed_count: 0,
  repositories_synced_count: 12,
  repositories_verification_total_count: 12,
  repositories_verified_count: 0,
  repositories_verification_failed_count: 12,
  wikis_count: 12,
  wikis_failed_count: 6,
  wikis_synced_count: 6,
  designs_count: 12,
  designs_failed_count: 0,
  designs_synced_count: 0,
  package_files_count: 25,
  package_files_synced_count: 25,
  package_files_failed_count: 0,
  db_replication_lag_seconds: 0,
  last_event_id: 3,
  last_event_timestamp: 1511255200,
  cursor_last_event_id: 3,
  cursor_last_event_timestamp: 1511255200,
  version: '10.4.0-pre',
  revision: 'b93c51849b',
  storage_shards_match: true,
  web_geo_projects_url: 'http://127.0.0.1:3002/replication/projects',
  web_geo_replication_details_url:
    'http://127.0.0.1:3002/admin/geo/sites/2/replication/lfs_objects',
};

export const MOCK_NODE_STATUSES_RES = [
  MOCK_PRIMARY_NODE_STATUSES_RES,
  MOCK_SECONDARY_NODE_STATUSES_RES,
];

export const MOCK_FILTER_NODES = [
  {
    name: 'healthy1',
    url: 'url/1',
    healthStatus: 'Healthy',
  },
  {
    name: 'healthy2',
    url: 'url/2',
    healthStatus: 'Healthy',
  },
  {
    name: 'unhealthy1',
    url: 'url/3',
    healthStatus: 'Unhealthy',
  },
  {
    name: 'disabled1',
    url: 'url/4',
    healthStatus: 'Disabled',
  },
  {
    name: 'offline1',
    url: 'url/5',
    healthStatus: 'Offline',
  },
  {
    name: 'unknown1',
    url: 'url/6',
    healthStatus: null,
  },
];

export const MOCK_NOT_CONFIGURED_EMPTY_STATE = {
  title: 'Discover GitLab Geo',
  description:
    'Make everyone on your team more productive regardless of their location. GitLab Geo creates read-only mirrors of your GitLab instance so you can reduce the time it takes to clone and fetch large repos.',
  showLearnMoreButton: true,
};

export const MOCK_NO_RESULTS_EMPTY_STATE = {
  title: 'No Geo site found',
  description: 'Edit your search and try again.',
  showLearnMoreButton: false,
};
