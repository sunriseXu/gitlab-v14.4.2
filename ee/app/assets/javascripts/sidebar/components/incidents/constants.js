import { s__, __ } from '~/locale';
import { SIDEBAR_ESCALATION_POLICY_TITLE, none } from '../../constants';

export const i18nHelpText = {
  title: s__('IncidentManagement|Page your team with escalation policies'),
  detail: s__(
    'IncidentManagement|Use escalation policies to automatically page your team when incidents are created.',
  ),
  linkText: __('Learn more'),
};

export const i18nPolicyText = {
  paged: s__('IncidentManagement|Paged'),
  title: SIDEBAR_ESCALATION_POLICY_TITLE,
  none,
};

export const i18nStatusText = {
  dropdownHeader: s__('IncidentManagement|Assign paging status'),
  dropdownInfo: s__(
    'IncidentManagement|Setting the status to Acknowledged or Resolved stops paging when escalation policies are selected for the incident.',
  ),
  learnMoreShort: __('Learn More.'),
  learnMoreFull: s__('IncidentManagement|Learn more about incident statuses'),
};
