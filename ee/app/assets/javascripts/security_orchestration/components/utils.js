import axios from '~/lib/utils/axios_utils';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { NAMESPACE_TYPES } from '../constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from './constants';

export const getProjectPoliciesUrl = (fullPath) => {
  return joinPaths(getBaseURL(), fullPath, '-', 'security', 'policies');
};

export const getSourceUrl = (fullPath, isGroup = true) => {
  return joinPaths(getBaseURL(), isGroup ? 'groups' : '', fullPath, '-', 'security', 'policies');
};

export const getSchemaUrl = ({ namespacePath, namespaceType }) => {
  const policyListUrl = getSourceUrl(namespacePath, namespaceType === NAMESPACE_TYPES.GROUP);
  return joinPaths(policyListUrl, 'schema');
};

export const isPolicyInherited = (source) => {
  if (source?.inherited === true) {
    return true;
  }

  return false;
};

export const getSingleScanExecutionPolicySchema = async ({ namespacePath, namespaceType }) => {
  try {
    const { data: schemaForMultiplePolicies } = await axios.get(
      getSchemaUrl({ namespacePath, namespaceType }),
    );
    return {
      $id: schemaForMultiplePolicies.$id,
      title: schemaForMultiplePolicies.title,
      description: schemaForMultiplePolicies.description,
      type: schemaForMultiplePolicies.type,
      properties: {
        type: {
          type: 'string',
          // eslint-disable-next-line @gitlab/require-i18n-strings
          description: 'Specifies the type of policy to be enforced.',
          enum: [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter],
        },
        ...schemaForMultiplePolicies.properties.scan_execution_policy.items.properties,
      },
    };
  } catch {
    return {};
  }
};
