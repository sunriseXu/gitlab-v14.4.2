import MaxExpirationDateMessage from 'ee/access_tokens/components/max_expiration_date_message.vue';

import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('MaxExpirationDateMessage', () => {
  let wrapper;

  const defaultPropsData = {
    maxDate: new Date('2022-3-2'),
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = mountExtended(MaxExpirationDateMessage, {
      propsData,
    });
  };

  describe('when `maxDate` is set', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders max date expiration message', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when `maxDate` is not set', () => {
    beforeEach(() => {
      createComponent({});
    });

    it('does not render anything', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
