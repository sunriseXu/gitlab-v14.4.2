import { __, s__ } from '~/locale';

export const RUNNER_TYPENAME = 'CiRunner'; // __typename

export const RUNNER_PAGE_SIZE = 20;
export const RUNNER_JOB_COUNT_LIMIT = 1000;

export const RUNNER_DETAILS_PROJECTS_PAGE_SIZE = 5;
export const RUNNER_DETAILS_JOBS_PAGE_SIZE = 30;

export const I18N_FETCH_ERROR = s__('Runners|Something went wrong while fetching runner data.');
export const I18N_DETAILS_TITLE = s__('Runners|Runner #%{runner_id}');

// Type

export const I18N_ALL_TYPES = s__('Runners|All');
export const I18N_INSTANCE_TYPE = s__('Runners|Instance');
export const I18N_GROUP_TYPE = s__('Runners|Group');
export const I18N_PROJECT_TYPE = s__('Runners|Project');
export const I18N_INSTANCE_RUNNER_DESCRIPTION = s__('Runners|Available to all projects');
export const I18N_GROUP_RUNNER_DESCRIPTION = s__(
  'Runners|Available to all projects and subgroups in the group',
);
export const I18N_PROJECT_RUNNER_DESCRIPTION = s__('Runners|Associated with one or more projects');

// Status
export const I18N_STATUS_ONLINE = s__('Runners|Online');
export const I18N_STATUS_NEVER_CONTACTED = s__('Runners|Never contacted');
export const I18N_STATUS_OFFLINE = s__('Runners|Offline');
export const I18N_STATUS_STALE = s__('Runners|Stale');

// Status help popover
export const I18N_STATUS_POPOVER_TITLE = s__('Runners|Runner statuses');

export const I18N_STATUS_POPOVER_NEVER_CONTACTED = s__('Runners|Never contacted:');
export const I18N_STATUS_POPOVER_NEVER_CONTACTED_DESCRIPTION = s__(
  'Runners|Runner has never contacted GitLab (when you register a runner, use %{codeStart}gitlab-runner run%{codeEnd} to bring it online)',
);
export const I18N_STATUS_POPOVER_ONLINE = s__('Runners|Online:');
export const I18N_STATUS_POPOVER_ONLINE_DESCRIPTION = s__(
  'Runners|Runner has contacted GitLab within the last %{elapsedTime}',
);
export const I18N_STATUS_POPOVER_OFFLINE = s__('Runners|Offline:');
export const I18N_STATUS_POPOVER_OFFLINE_DESCRIPTION = s__(
  'Runners|Runner has not contacted GitLab in more than %{elapsedTime}',
);
export const I18N_STATUS_POPOVER_STALE = s__('Runners|Stale:');
export const I18N_STATUS_POPOVER_STALE_DESCRIPTION = s__(
  'Runners|Runner has not contacted GitLab in more than %{elapsedTime}',
);

// Status tooltips
export const I18N_ONLINE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is online; last contact was %{timeAgo}',
);
export const I18N_NEVER_CONTACTED_TOOLTIP = s__('Runners|Runner has never contacted this instance');
export const I18N_OFFLINE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is offline; last contact was %{timeAgo}',
);
export const I18N_STALE_TIMEAGO_TOOLTIP = s__(
  'Runners|Runner is stale; last contact was %{timeAgo}',
);
export const I18N_STALE_NEVER_CONTACTED_TOOLTIP = s__(
  'Runners|Runner is stale; it has never contacted this instance',
);

// Actions
export const I18N_EDIT = __('Edit');

export const I18N_PAUSE = __('Pause');
export const I18N_PAUSED = s__('Runners|Paused');
export const I18N_PAUSE_TOOLTIP = s__('Runners|Pause from accepting jobs');
export const I18N_PAUSED_DESCRIPTION = s__('Runners|Not accepting jobs');

export const I18N_RESUME = __('Resume');
export const I18N_RESUME_TOOLTIP = s__('Runners|Resume accepting jobs');

export const I18N_DELETE_RUNNER = s__('Runners|Delete runner');
export const I18N_DELETE_DISABLED_MANY_PROJECTS = s__(
  'Runners|Multi-project runners cannot be deleted',
);
export const I18N_DELETE_DISABLED_UNKNOWN_REASON = s__(
  'Runners|Runner cannot be deleted, please contact your administrator',
);
export const I18N_DELETED_TOAST = s__('Runners|Runner %{name} was deleted');

// List
export const I18N_LOCKED_RUNNER_DESCRIPTION = s__(
  'Runners|Runner is locked and available for currently assigned projects only. Only administrators can change the assigned projects.',
);
export const I18N_VERSION_LABEL = s__('Runners|Version %{version}');
export const I18N_LAST_CONTACT_LABEL = s__('Runners|Last contact: %{timeAgo}');
export const I18N_CREATED_AT_LABEL = s__('Runners|Created %{timeAgo}');

// Runner details

export const I18N_DETAILS = s__('Runners|Details');
export const I18N_ASSIGNED_PROJECTS = s__('Runners|Assigned Projects (%{projectCount})');
export const I18N_FILTER_PROJECTS = s__('Runners|Filter projects');
export const I18N_CLEAR_FILTER_PROJECTS = __('Clear');
export const I18N_NONE = __('None');
export const I18N_NO_JOBS_FOUND = s__('Runners|This runner has not run any jobs.');
export const I18N_NO_PROJECTS_FOUND = __('No projects found');

// Styles

export const RUNNER_TAG_BADGE_VARIANT = 'info';
export const RUNNER_TAG_BG_CLASS = 'gl-bg-blue-100';

// Filtered search parameter names
// - Used for URL params names
// - GlFilteredSearch tokens type

export const PARAM_KEY_STATUS = 'status';
export const PARAM_KEY_PAUSED = 'paused';
export const PARAM_KEY_RUNNER_TYPE = 'runner_type';
export const PARAM_KEY_TAG = 'tag';
export const PARAM_KEY_SEARCH = 'search';

export const PARAM_KEY_SORT = 'sort';
export const PARAM_KEY_AFTER = 'after';
export const PARAM_KEY_BEFORE = 'before';

// CiRunnerType

export const INSTANCE_TYPE = 'INSTANCE_TYPE';
export const GROUP_TYPE = 'GROUP_TYPE';
export const PROJECT_TYPE = 'PROJECT_TYPE';

// CiRunnerStatus

export const STATUS_ONLINE = 'ONLINE';
export const STATUS_NEVER_CONTACTED = 'NEVER_CONTACTED';
export const STATUS_OFFLINE = 'OFFLINE';
export const STATUS_STALE = 'STALE';

// CiRunnerAccessLevel

export const ACCESS_LEVEL_NOT_PROTECTED = 'NOT_PROTECTED';
export const ACCESS_LEVEL_REF_PROTECTED = 'REF_PROTECTED';

// CiRunnerSort

export const CREATED_DESC = 'CREATED_DESC';
export const CREATED_ASC = 'CREATED_ASC';
export const CONTACTED_DESC = 'CONTACTED_DESC';
export const CONTACTED_ASC = 'CONTACTED_ASC';

export const DEFAULT_SORT = CREATED_DESC;

// Local storage namespaces

export const ADMIN_FILTERED_SEARCH_NAMESPACE = 'admin_runners';
export const GROUP_FILTERED_SEARCH_NAMESPACE = 'group_runners';
