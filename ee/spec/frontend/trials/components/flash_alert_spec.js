import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FlashAlert from 'ee/trials/components/flash_alert.vue';

describe('FlashAlert', () => {
  let wrapper;

  const createComponent = ({ errors = null } = {}) => {
    wrapper = shallowMount(FlashAlert, {
      propsData: { errors },
    });
  };

  const errors = 'this is an error';
  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    createComponent({ errors });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows an alert', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('is dismissible', () => {
    expect(findAlert().props('dismissible')).toBe(false);
  });

  it('is of type danger', () => {
    expect(findAlert().props('variant')).toBe('danger');
  });

  it('contains the error message', () => {
    expect(findAlert().text()).toContain(errors);
  });
});
