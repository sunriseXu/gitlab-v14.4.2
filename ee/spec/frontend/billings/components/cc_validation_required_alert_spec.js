import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import AccountVerificationModal from 'ee/billings/components/account_verification_modal.vue';
import CreditCardValidationRequiredAlert from 'ee/billings/components/cc_validation_required_alert.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { stubComponent } from 'helpers/stub_component';

describe('CreditCardValidationRequiredAlert', () => {
  let showSpy;
  let trackingSpy;
  let wrapper;

  const createComponent = ({ data = {}, props = {} } = {}) => {
    showSpy = jest.fn();

    return shallowMount(CreditCardValidationRequiredAlert, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
        AccountVerificationModal: stubComponent(AccountVerificationModal, {
          methods: { show: showSpy, hide: jest.fn() },
        }),
      },
      data() {
        return data;
      },
    });
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

    window.gon = {
      subscriptions_url: TEST_HOST,
      payment_form_url: TEST_HOST,
    };

    wrapper = createComponent();
    wrapper.vm.$refs.modal.hide = jest.fn();
  });

  afterEach(() => {
    unmockTracking();
    wrapper.destroy();
  });

  it('renders title', () => {
    expect(findGlAlert().attributes('title')).toBe('User validation required');
  });

  it('renders description', () => {
    expect(findGlAlert().text()).toContain('To use free CI/CD minutes');
  });

  it('renders danger alert', () => {
    expect(findGlAlert().attributes('variant')).toBe('danger');
  });

  it('renders the success alert instead of danger', () => {
    wrapper = createComponent({ data: { shouldRenderSuccess: true } });

    expect(findGlAlert().attributes('variant')).toBe('success');
  });

  it('hides the modal and emits a verifiedCreditCard event upon success', () => {
    wrapper.findComponent(AccountVerificationModal).vm.$emit('success');

    expect(wrapper.vm.$refs.modal.hide).toHaveBeenCalled();
    expect(wrapper.emitted('verifiedCreditCard')).toBeDefined();
  });

  it('danger alert emits dismiss event on dismiss', () => {
    findGlAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismiss')).toBeDefined();
  });

  it('does not open the modal on mount', () => {
    expect(showSpy).not.toHaveBeenCalled();
  });

  describe('when isFromAccountValidationEmail prop is true', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { isFromAccountValidationEmail: true } });
    });

    it('opens the modal on mount', () => {
      expect(showSpy).toHaveBeenCalled();
    });

    it('sends successful verification event', () => {
      wrapper.findComponent(AccountVerificationModal).vm.$emit('success');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'successful_validation', {
        label: 'account_validation_email',
      });
    });
  });
});
