import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrationToken from '~/runner/components/registration/registration_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

const mockToken = '01234567890';
const mockMasked = '***********';

describe('RegistrationToken', () => {
  let wrapper;
  let showToast;

  Vue.use(GlToast);

  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RegistrationToken, {
      propsData: {
        value: mockToken,
        inputId: 'token-value',
        ...props,
      },
    });

    showToast = wrapper.vm.$toast ? jest.spyOn(wrapper.vm.$toast, 'show') : null;
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays value and copy button', () => {
    createComponent();

    expect(findInputCopyToggleVisibility().props('value')).toBe(mockToken);
    expect(findInputCopyToggleVisibility().props('copyButtonTitle')).toBe(
      'Copy registration token',
    );
  });

  // Component integration test to ensure secure masking
  it('Displays masked value by default', () => {
    createComponent({ mountFn: mountExtended });

    expect(wrapper.find('input').element.value).toBe(mockMasked);
  });

  describe('When the copy to clipboard button is clicked', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a copied message', () => {
      findInputCopyToggleVisibility().vm.$emit('copy');

      expect(showToast).toHaveBeenCalledTimes(1);
      expect(showToast).toHaveBeenCalledWith('Registration token copied!');
    });
  });
});
