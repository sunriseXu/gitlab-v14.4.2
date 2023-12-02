import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SourceEditorToolbarButton from '~/editor/components/source_editor_toolbar_button.vue';
import { buildButton } from './helpers';

describe('Source Editor Toolbar button', () => {
  let wrapper;
  const defaultBtn = buildButton();

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = { button: defaultBtn }) => {
    wrapper = shallowMount(SourceEditorToolbarButton, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    const defaultProps = {
      category: 'primary',
      variant: 'default',
    };
    const customProps = {
      category: 'secondary',
      variant: 'info',
    };

    it('does not render the button if the props have not been passed', () => {
      createComponent({});
      expect(findButton().vm).toBeUndefined();
    });

    it('renders a default button without props', async () => {
      createComponent();
      const btn = findButton();
      expect(btn.exists()).toBe(true);
      expect(btn.props()).toMatchObject(defaultProps);
    });

    it('renders a button based on the props passed', async () => {
      createComponent({
        button: customProps,
      });
      const btn = findButton();
      expect(btn.props()).toMatchObject(customProps);
    });
  });

  describe('click handler', () => {
    it('fires the click handler on the button when available', async () => {
      const spy = jest.fn();
      createComponent({
        button: {
          onClick: spy,
        },
      });
      expect(spy).not.toHaveBeenCalled();
      findButton().vm.$emit('click');

      await nextTick();
      expect(spy).toHaveBeenCalled();
    });
    it('emits the "click" event', async () => {
      createComponent();
      jest.spyOn(wrapper.vm, '$emit');
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();

      findButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('click');
    });
  });
});
