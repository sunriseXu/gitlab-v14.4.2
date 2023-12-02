import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyPreviewHuman from 'ee/security_orchestration/components/policy_editor/policy_preview_human.vue';

describe('PolicyPreviewHuman component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMount(PolicyPreviewHuman, {
      propsData: {
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when policy description is not defined', () => {
    beforeEach(() => {
      factory();
    });

    it('renders an alert when policyDescription is not defined', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('when policy description is defined', () => {
    const policyDescription = '<strong>bar</strong><br><div>test</div><script></script>';
    const policyDescriptionSafe = '<strong>bar</strong><br>test';

    beforeEach(() => {
      factory({
        propsData: {
          policyDescription,
        },
      });
    });

    it('renders the policyDescription when it is defined', () => {
      expect(wrapper.html()).toContain(policyDescriptionSafe);
    });

    it('does not render the alert component', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });
});
