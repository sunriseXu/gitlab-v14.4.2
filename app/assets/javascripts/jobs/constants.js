import { __, s__ } from '~/locale';

const cancel = __('Cancel');
const moreInfo = __('More information');

export const forwardDeploymentFailureModalId = 'forward-deployment-failure';

export const JOB_SIDEBAR_COPY = {
  cancel,
  cancelJobButtonLabel: s__('Job|Cancel'),
  debug: __('Debug'),
  eraseLogButtonLabel: s__('Job|Erase job log and artifacts'),
  eraseLogConfirmText: s__('Job|Are you sure you want to erase this job log and artifacts?'),
  newIssue: __('New issue'),
  retry: __('Retry'),
  retryJobButtonLabel: s__('Job|Retry'),
  toggleSidebar: __('Toggle Sidebar'),
};

export const JOB_RETRY_FORWARD_DEPLOYMENT_MODAL = {
  cancel,
  info: s__(
    `Jobs|You're about to retry a job that failed because it attempted to deploy code that is older than the latest deployment.
    Retrying this job could result in overwriting the environment with the older source code.`,
  ),
  areYouSure: s__('Jobs|Are you sure you want to proceed?'),
  moreInfo,
  primaryText: __('Retry job'),
  title: s__('Jobs|Are you sure you want to retry this job?'),
};

export const SUCCESS_STATUS = 'SUCCESS';
