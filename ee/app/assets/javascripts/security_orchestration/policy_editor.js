import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import NewPolicyApp from './components/policy_editor/new_policy.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from './constants';
import createStore from './store';
import { gqClient } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: gqClient,
});

export default (el, namespaceType) => {
  const {
    assignedPolicyProject,
    disableScanPolicyUpdate,
    createAgentHelpPath,
    namespaceId,
    namespacePath,
    policiesPath,
    policy,
    policyEditorEmptyStateSvgPath,
    policyType,
    scanPolicyDocumentationPath,
    scanResultApprovers,
  } = el.dataset;

  const policyProject = JSON.parse(assignedPolicyProject);

  const scanResultPolicyApprovers = scanResultApprovers ? JSON.parse(scanResultApprovers) : [];

  return new Vue({
    el,
    apolloProvider,
    provide: {
      createAgentHelpPath,
      disableScanPolicyUpdate: parseBoolean(disableScanPolicyUpdate),
      namespaceId,
      namespacePath,
      namespaceType,
      policyEditorEmptyStateSvgPath,
      policyType,
      policiesPath,
      scanPolicyDocumentationPath,
      scanResultPolicyApprovers,
      existingPolicy: policy ? { type: policyType, ...JSON.parse(policy) } : undefined,
      assignedPolicyProject: policyProject
        ? convertObjectPropsToCamelCase(policyProject)
        : DEFAULT_ASSIGNED_POLICY_PROJECT,
    },
    store: createStore(),
    render(createElement) {
      return createElement(NewPolicyApp);
    },
  });
};
