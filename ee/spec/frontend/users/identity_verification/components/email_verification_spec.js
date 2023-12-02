import { GlForm, GlFormInput, GlButton, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { s__ } from '~/locale';
import { createAlert, VARIANT_SUCCESS } from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import EmailVerification from 'ee/users/identity_verification/components/email_verification.vue';
import { I18N_EMAIL_VERIFICATION } from 'ee/users/identity_verification/constants';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('EmailVerification', () => {
  let wrapper;
  let axiosMock;

  const emailObfuscated = 'al**@g*****.com';
  const emailVerifyPath = '/users/identity_verification/verify_email_code';
  const emailResendPath = '/users/identity_verification/resend_email_code';

  const createComponent = () => {
    wrapper = mount(EmailVerification, {
      provide: { emailObfuscated, emailVerifyPath, emailResendPath },
    });
  };

  const findHeader = () => wrapper.find('p');
  const findForm = () => wrapper.findComponent(GlForm);
  const findCodeInput = () => wrapper.findComponent(GlFormInput);
  const findSubmitButton = () => wrapper.findComponent(GlButton);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');
  const findResendLink = () => wrapper.findComponent(GlLink);

  const enterCode = (code) => findCodeInput().setValue(code);
  const submitForm = () => findForm().trigger('submit');

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    createAlert.mockClear();
    axiosMock.restore();
  });

  describe('rendering the form', () => {
    it('contains the obfuscated email address', () => {
      expect(findHeader().text()).toContain(emailObfuscated);
    });
  });

  describe('verifying the code', () => {
    describe('when successfully verifying the code', () => {
      it('redirects to the returned redirect_url', async () => {
        enterCode('123456');

        axiosMock.onPost(emailVerifyPath).reply(200, { status: 'success', redirect_url: 'root' });

        await submitForm();
        await axios.waitForAll();

        expect(visitUrl).toHaveBeenCalledWith('root');
      });
    });

    describe('error messages', () => {
      it.each`
        scenario                                                         | code        | submit   | codeValid | errorShown | message
        ${'shows no error messages before submitting the form'}          | ${''}       | ${false} | ${false}  | ${false}   | ${''}
        ${'shows no error messages before submitting the form'}          | ${'xxx'}    | ${false} | ${false}  | ${false}   | ${''}
        ${'shows no error messages before submitting the form'}          | ${'123456'} | ${false} | ${true}   | ${false}   | ${''}
        ${'shows empty code error message when submitting the form'}     | ${''}       | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_VERIFICATION.emptyCode}
        ${'shows invalid error message when submitting the form'}        | ${'xxx'}    | ${true}  | ${false}  | ${true}    | ${I18N_EMAIL_VERIFICATION.invalidCode}
        ${'shows incorrect code error message returned from the server'} | ${'123456'} | ${true}  | ${true}   | ${true}    | ${s__('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')}
      `(`$scenario with code $code`, async ({ code, submit, codeValid, errorShown, message }) => {
        enterCode(code);

        if (submit && codeValid) {
          axiosMock.onPost(emailVerifyPath).replyOnce(200, { status: 'failure', message });
        }

        if (submit) {
          await submitForm();
          await axios.waitForAll();
        }

        expect(findCodeInput().classes('is-invalid')).toBe(errorShown);
        expect(findErrorMessage().exists()).toBe(errorShown);
        expect(findSubmitButton().props('disabled')).toBe(errorShown);
        if (errorShown) expect(findErrorMessage().text()).toBe(message);
      });

      it('keeps showing error messages for invalid codes after submitting the form', async () => {
        enterCode('123456');

        axiosMock
          .onPost(emailVerifyPath)
          .replyOnce(200, { status: 'failure', message: 'error message' });

        await submitForm();
        await axios.waitForAll();

        expect(findErrorMessage().text()).toBe('error message');

        await enterCode('');
        expect(findErrorMessage().text()).toBe(I18N_EMAIL_VERIFICATION.emptyCode);

        await enterCode('xxx');
        expect(findErrorMessage().text()).toBe(I18N_EMAIL_VERIFICATION.invalidCode);

        await enterCode('123456');
        expect(findErrorMessage().exists()).toBe(false);
      });

      it('captures the error and shows a flash message when the request failed', async () => {
        enterCode('123456');

        axiosMock.onPost(emailVerifyPath).replyOnce(404);

        await submitForm();
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_EMAIL_VERIFICATION.requestError,
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('resending the code', () => {
    it.each`
      scenario                                    | statusCode | response
      ${'the code was successfully resend'}       | ${200}     | ${{ status: 'success' }}
      ${'there was a problem resending the code'} | ${200}     | ${{ status: 'failure', message: 'Failure sending the code' }}
      ${'when the request failed'}                | ${404}     | ${null}
    `(`shows a flash message when $scenario`, async ({ statusCode, response }) => {
      enterCode('xxx');

      await submitForm();

      axiosMock.onPost(emailResendPath).replyOnce(statusCode, response);

      findResendLink().trigger('click');

      await axios.waitForAll();

      let alertObject;
      if (statusCode === 200 && response.status === 'success') {
        alertObject = {
          message: I18N_EMAIL_VERIFICATION.resendSuccess,
          variant: VARIANT_SUCCESS,
        };
      } else if (statusCode === 200) {
        alertObject = { message: response.message };
      } else {
        alertObject = {
          message: I18N_EMAIL_VERIFICATION.requestError,
          captureError: true,
          error: expect.any(Error),
        };
      }
      expect(createAlert).toHaveBeenCalledWith(alertObject);

      expect(findCodeInput().element.value).toBe('');
      expect(findErrorMessage().exists()).toBe(false);
    });
  });
});
