import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import PolicyEditor from 'ee/security_orchestration/components/policy_editor/policy_editor.vue';
import ScanExecutionPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_result_policy_editor.vue';
import {
  DEFAULT_ASSIGNED_POLICY_PROJECT,
  NAMESPACE_TYPES,
} from 'ee/security_orchestration/constants';

describe('PolicyEditor component', () => {
  let wrapper;

  const findGroupLevelNotification = () => wrapper.findByTestId('group-level-notification');
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findScanExecutionPolicyEditor = () => wrapper.findComponent(ScanExecutionPolicyEditor);
  const findScanResultPolicyEditor = () => wrapper.findComponent(ScanResultPolicyEditor);

  const factory = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(PolicyEditor, {
      propsData: {
        selectedPolicyType: 'container',
      },
      provide: {
        assignedPolicyProject: DEFAULT_ASSIGNED_POLICY_PROJECT,
        namespaceType: NAMESPACE_TYPES.PROJECT,
        policyType: undefined,
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('project-level', () => {
    beforeEach(factory);

    it.each`
      component              | findComponent
      ${'group-level alert'} | ${findGroupLevelNotification}
      ${'error alert'}       | ${findErrorAlert}
    `('does not display the $component', ({ findComponent }) => {
      expect(findComponent().exists()).toBe(false);
    });

    it('renders the network policy editor component', () => {
      expect(findScanExecutionPolicyEditor().props('existingPolicy')).toBe(null);
    });

    it('shows an alert when "error" is emitted from the component', async () => {
      const errorMessage = 'test';
      findScanExecutionPolicyEditor().vm.$emit('error', errorMessage);
      await nextTick();
      const alert = findErrorAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe(errorMessage);
    });

    it('shows an alert with details when multiline "error" is emitted from the component', async () => {
      const errorMessages = 'title\ndetail1';
      findScanExecutionPolicyEditor().vm.$emit('error', errorMessages);
      await nextTick();
      const alert = findErrorAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe('title');
      expect(alert.text()).toBe('detail1');
    });

    it.each`
      policyTypeId                                         | findComponent
      ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value} | ${findScanExecutionPolicyEditor}
      ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value}    | ${findScanResultPolicyEditor}
    `(
      'renders the policy editor of type $policyType when selected',
      async ({ findComponent, policyTypeId }) => {
        wrapper.setProps({ selectedPolicyType: policyTypeId });
        await nextTick();
        const component = findComponent();
        expect(component.exists()).toBe(true);
        expect(component.props('isEditing')).toBe(false);
      },
    );
  });

  describe('group-level', () => {
    beforeEach(() => {
      factory({ provide: { namespaceType: NAMESPACE_TYPES.GROUP } });
    });

    it('does display the group-level alert', () => {
      expect(findGroupLevelNotification().exists()).toBe(true);
    });
  });
});
