import { GlEmptyState } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_action_builder.vue';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_rule_builder.vue';
import PolicyEditorLayout from 'ee/security_orchestration/components/policy_editor/policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  buildScannerAction,
  fromYaml,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';
import ScanExecutionPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from 'ee/security_orchestration/constants';
import {
  mockDastScanExecutionManifest,
  mockDastScanExecutionObject,
} from 'ee_jest/security_orchestration/mocks/mock_data';
import { visitUrl } from '~/lib/utils/url_utility';

import { modifyPolicy } from 'ee/security_orchestration/components/policy_editor/utils';
import {
  EDITOR_MODES,
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  SECURITY_POLICY_ACTIONS,
} from 'ee/security_orchestration/components/policy_editor/constants';
import {
  DEFAULT_SCANNER,
  SCAN_EXECUTION_PIPELINE_RULE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { RULE_KEY_MAP } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib/rules';

jest.mock('~/lib/utils/url_utility', () => ({
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  visitUrl: jest.fn().mockName('visitUrlMock'),
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
}));

const newlyCreatedPolicyProject = {
  branch: 'main',
  fullPath: 'path/to/new-project',
};

jest.mock('ee/security_orchestration/components/policy_editor/utils', () => ({
  assignSecurityPolicyProject: jest.fn().mockResolvedValue({
    branch: 'main',
    fullPath: 'path/to/new-project',
  }),
  modifyPolicy: jest.fn().mockResolvedValue({ id: '2' }),
  isValidPolicy: jest.requireActual('ee/security_orchestration/components/policy_editor/utils')
    .isValidPolicy,
}));

describe('ScanExecutionPolicyEditor', () => {
  let wrapper;
  const defaultProjectPath = 'path/to/project';
  const policyEditorEmptyStateSvgPath = 'path/to/svg';
  const scanPolicyDocumentationPath = 'path/to/docs';
  const assignedPolicyProject = {
    branch: 'main',
    fullPath: 'path/to/existing-project',
  };

  const factory = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(ScanExecutionPolicyEditor, {
      propsData: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        ...propsData,
      },
      provide: {
        disableScanPolicyUpdate: false,
        policyEditorEmptyStateSvgPath,
        namespacePath: defaultProjectPath,
        scanPolicyDocumentationPath,
        glFeatures: {
          scanExecutionRuleMode: false,
        },
        ...provide,
      },
    });
  };

  const factoryWithExistingPolicy = () => {
    return factory({
      propsData: {
        assignedPolicyProject,
        existingPolicy: mockDastScanExecutionObject,
        isEditing: true,
      },
    });
  };

  const findAddActionButton = () => wrapper.findByTestId('add-action');
  const findAddRuleButton = () => wrapper.findByTestId('add-rule');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);
  const findPolicyActionBuilder = () => wrapper.findComponent(PolicyActionBuilder);
  const findAllPolicyActionBuilders = () => wrapper.findAllComponents(PolicyActionBuilder);
  const findPolicyRuleBuilder = () => wrapper.findComponent(PolicyRuleBuilder);
  const findAllPolicyRuleBuilders = () => wrapper.findAllComponents(PolicyRuleBuilder);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    it('displays the correct modes', async () => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().attributes('editormodes')).toBe(EDITOR_MODES[1].toString());
    });

    it('defaults to yaml mode', async () => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().attributes('defaulteditormode')).toBe(EDITOR_MODE_YAML);
    });

    it('updates the policy yaml when "update-yaml" is emitted', async () => {
      factory();
      await nextTick();
      const newManifest = 'new yaml!';
      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
        DEFAULT_SCAN_EXECUTION_POLICY,
      );
      await findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
    });

    it.each`
      status                            | action                             | event              | factoryFn                    | yamlEditorValue                  | currentlyAssignedPolicyProject
      ${'to save a new policy'}         | ${SECURITY_POLICY_ACTIONS.APPEND}  | ${'save-policy'}   | ${factory}                   | ${DEFAULT_SCAN_EXECUTION_POLICY} | ${newlyCreatedPolicyProject}
      ${'to update an existing policy'} | ${SECURITY_POLICY_ACTIONS.REPLACE} | ${'save-policy'}   | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
      ${'to delete an existing policy'} | ${SECURITY_POLICY_ACTIONS.REMOVE}  | ${'remove-policy'} | ${factoryWithExistingPolicy} | ${mockDastScanExecutionManifest} | ${assignedPolicyProject}
    `(
      'navigates to the new merge request when "modifyPolicy" is emitted $status',
      async ({ action, event, factoryFn, yamlEditorValue, currentlyAssignedPolicyProject }) => {
        factoryFn();
        await nextTick();
        findPolicyEditorLayout().vm.$emit(event);
        await waitForPromises();
        expect(modifyPolicy).toHaveBeenCalledTimes(1);
        expect(modifyPolicy).toHaveBeenCalledWith({
          action,
          assignedPolicyProject: currentlyAssignedPolicyProject,
          name:
            action === SECURITY_POLICY_ACTIONS.APPEND
              ? fromYaml(yamlEditorValue).name
              : mockDastScanExecutionObject.name,
          namespacePath: defaultProjectPath,
          yamlEditorValue,
        });
        await nextTick();
        expect(visitUrl).toHaveBeenCalled();
        expect(visitUrl).toHaveBeenCalledWith(
          `/${currentlyAssignedPolicyProject.fullPath}/-/merge_requests/2`,
        );
      },
    );
  });

  describe('when a user is not an owner of the project', () => {
    it('displays the empty state with the appropriate properties', async () => {
      factory({ provide: { disableScanPolicyUpdate: true } });
      await nextTick();
      const emptyState = findEmptyState();

      expect(emptyState.props('primaryButtonLink')).toMatch(scanPolicyDocumentationPath);
      expect(emptyState.props('primaryButtonLink')).toMatch('scan-execution-policy-editor');
      expect(emptyState.props('svgPath')).toBe(policyEditorEmptyStateSvgPath);
    });
  });

  describe('scan execution rule mode feature flag', () => {
    beforeEach(() => {
      factory({ provide: { glFeatures: { scanExecutionRuleMode: true } } });
    });

    it('displays the correct modes', () => {
      expect(findPolicyEditorLayout().attributes('editormodes')).toBe(EDITOR_MODES.toString());
    });

    it('defaults to rule mode', () => {
      expect(findPolicyEditorLayout().attributes('defaulteditormode')).toBe(EDITOR_MODE_RULE);
    });

    it('updates the policy yaml when "update-yaml" is emitted', async () => {
      const newManifest = 'new yaml!';
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
        DEFAULT_SCAN_EXECUTION_POLICY,
      );

      findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
      await nextTick();

      expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(newManifest);
    });

    it.each`
      component        | oldValue | newValue
      ${'name'}        | ${''}    | ${'new policy name'}
      ${'description'} | ${''}    | ${'new description'}
      ${'enabled'}     | ${true}  | ${false}
    `('triggers a change on $component', async ({ component, newValue, oldValue }) => {
      factory();
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(oldValue);

      findPolicyEditorLayout().vm.$emit('set-policy-property', component, newValue);
      await nextTick();

      expect(findPolicyEditorLayout().props('policy')[component]).toBe(newValue);
    });
  });

  describe('policy rule builder', () => {
    beforeEach(() => {
      factory({ provide: { glFeatures: { scanExecutionRuleMode: true } } });
    });

    it('should add new rule', async () => {
      expect(findPolicyEditorLayout().props('policy').rules).toEqual([
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
      ]);

      findAddRuleButton().vm.$emit('click');

      await nextTick();

      expect(findPolicyEditorLayout().props('policy').rules).toEqual([
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
        RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE](),
      ]);
    });

    it('should remove rule', async () => {
      findAddRuleButton().vm.$emit('click');
      await nextTick();

      expect(findAllPolicyRuleBuilders()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(2);

      findPolicyRuleBuilder().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllPolicyRuleBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').rules).toHaveLength(1);
    });
  });

  describe('policy action builder', () => {
    beforeEach(() => {
      factory({ provide: { glFeatures: { scanExecutionRuleMode: true } } });
    });

    it('should add new action', async () => {
      expect(findPolicyEditorLayout().props('policy').actions).toEqual([
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
      ]);
      findAddActionButton().vm.$emit('click');

      await nextTick();

      expect(findPolicyEditorLayout().props('policy').actions).toEqual([
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
        buildScannerAction({ scanner: DEFAULT_SCANNER }),
      ]);
    });

    it('should update action', async () => {
      const updatedAction = buildScannerAction({ scanner: 'sast' });
      findPolicyActionBuilder().vm.$emit('changed', updatedAction);
      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').actions[0]).toStrictEqual(updatedAction);
    });

    it('should remove action', async () => {
      findAddActionButton().vm.$emit('click');
      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(2);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(2);

      findPolicyActionBuilder().vm.$emit('remove', 1);
      await nextTick();

      expect(findAllPolicyActionBuilders()).toHaveLength(1);
      expect(findPolicyEditorLayout().props('policy').actions).toHaveLength(1);
    });
  });
});
