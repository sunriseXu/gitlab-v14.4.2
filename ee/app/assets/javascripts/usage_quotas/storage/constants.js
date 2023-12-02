import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching project storage statistics',
);

export const LEARN_MORE_LABEL = __('Learn more.');
export const USAGE_QUOTAS_LABEL = s__('UsageQuota|Usage Quotas');
export const HELP_LINK_ARIA_LABEL = s__('UsageQuota|%{linkTitle} help link');
export const TOTAL_USAGE_DEFAULT_TEXT = __('Not applicable.');
export const TOTAL_USAGE_TITLE = s__('UsageQuota|Usage breakdown');
export const TOTAL_USAGE_SUBTITLE = s__(
  'UsageQuota|Includes artifacts, repositories, wiki, uploads, and other items.',
);
export const RECALCULATE_REPOSITORY_LABEL = s__('UsageQuota|Recalculate repository usage');

export const PROJECT_STORAGE_TYPES = [
  {
    id: 'containerRegistrySize',
    name: s__('UsageQuota|Container Registry'),
    description: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
    ),
  },
  {
    id: 'buildArtifactsSize',
    name: s__('UsageQuota|Artifacts'),
    description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
    tooltip: s__('UsageQuota|Artifacts is a sum of build and pipeline artifacts.'),
  },
  {
    id: 'lfsObjectsSize',
    name: s__('UsageQuota|LFS storage'),
    description: s__('UsageQuota|Audio samples, videos, datasets, and graphics.'),
  },
  {
    id: 'packagesSize',
    name: s__('UsageQuota|Packages'),
    description: s__('UsageQuota|Code packages and container images.'),
  },
  {
    id: 'repositorySize',
    name: s__('UsageQuota|Repository'),
    description: s__('UsageQuota|Git repository.'),
  },
  {
    id: 'snippetsSize',
    name: s__('UsageQuota|Snippets'),
    description: s__('UsageQuota|Shared bits of code and text.'),
  },
  {
    id: 'uploadsSize',
    name: s__('UsageQuota|Uploads'),
    description: s__('UsageQuota|File attachments and smaller design graphics.'),
  },
  {
    id: 'wikiSize',
    name: s__('UsageQuota|Wiki'),
    description: s__('UsageQuota|Wiki content.'),
  },
];

export const PROJECT_TABLE_LABEL_PROJECT = __('Project');
export const PROJECT_TABLE_LABEL_STORAGE_TYPE = s__('UsageQuota|Storage type');
export const PROJECT_TABLE_LABEL_USAGE = s__('UsageQuota|Usage');
export const PROJECT_TABLE_LABEL_STORAGE_USAGE = s__('UsageQuota|Storage used');

export const STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE = s__(
  'UsageQuota|Learn more about usage quotas.',
);

export const STORAGE_STATISTICS_NAMESPACE_STORAGE_USED = s__('UsageQuota|Namespace storage used');

export const STORAGE_STATISTICS_PURCHASED_STORAGE_USED = s__('UsageQuota|Purchased storage used');

export const STORAGE_STATISTICS_PURCHASED_STORAGE = s__('UsageQuota|Purchased storage');

export const BUY_STORAGE = s__('UsageQuota|Buy storage');

export const SKELETON_LOADER_ROWS = 5;

export const NONE_THRESHOLD = 'none';
export const INFO_THRESHOLD = 'info';
export const WARNING_THRESHOLD = 'warning';
export const ALERT_THRESHOLD = 'alert';
export const ERROR_THRESHOLD = 'error';

export const STORAGE_USAGE_THRESHOLDS = {
  [NONE_THRESHOLD]: 0.0,
  [INFO_THRESHOLD]: 0.5,
  [WARNING_THRESHOLD]: 0.75,
  [ALERT_THRESHOLD]: 0.95,
  [ERROR_THRESHOLD]: 1.0,
};

export const projectHelpPaths = {
  containerRegistry: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
  ),
  usageQuotas: helpPagePath('user/usage_quotas'),
  buildArtifacts: helpPagePath('ci/pipelines/job_artifacts', {
    anchor: 'when-job-artifacts-are-deleted',
  }),
  packages: helpPagePath('user/packages/package_registry/index.md', {
    anchor: 'reduce-storage-usage',
  }),
  repository: helpPagePath('user/project/repository/reducing_the_repo_size_using_git'),
  snippets: helpPagePath('user/snippets', {
    anchor: 'reduce-snippets-repository-size',
  }),
  wiki: helpPagePath('administration/wikis/index.md', {
    anchor: 'reduce-wiki-repository-size',
  }),
};
