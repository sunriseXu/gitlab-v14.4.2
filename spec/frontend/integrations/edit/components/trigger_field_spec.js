import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';

import TriggerField from '~/integrations/edit/components/trigger_field.vue';
import { integrationTriggerEventTitles } from '~/integrations/constants';

describe('TriggerField', () => {
  let wrapper;

  const defaultProps = {
    event: { name: 'push_events' },
  };

  const createComponent = ({ props = {}, isInheriting = false } = {}) => {
    wrapper = shallowMount(TriggerField, {
      propsData: { ...defaultProps, ...props },
      computed: {
        isInheriting: () => isInheriting,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findHiddenInput = () => wrapper.find('input[type="hidden"]');

  describe('template', () => {
    it('renders enabled GlFormCheckbox', () => {
      createComponent();

      expect(findGlFormCheckbox().attributes('disabled')).toBeUndefined();
    });

    it('when isInheriting is true, renders disabled GlFormCheckbox', () => {
      createComponent({ isInheriting: true });

      expect(findGlFormCheckbox().attributes('disabled')).toBe('true');
    });

    it('renders correct title', () => {
      createComponent();

      expect(findGlFormCheckbox().text()).toMatchInterpolatedText(
        integrationTriggerEventTitles[defaultProps.event.name],
      );
    });

    it('sets default value for hidden input', () => {
      createComponent();

      expect(findHiddenInput().attributes('value')).toBe('false');
    });

    it('toggles value of hidden input on checkbox input', async () => {
      createComponent({
        props: { event: { name: 'push_events', value: true } },
      });
      await nextTick;

      expect(findHiddenInput().attributes('value')).toBe('true');

      await findGlFormCheckbox().vm.$emit('input', false);

      expect(findHiddenInput().attributes('value')).toBe('false');
    });
  });
});
