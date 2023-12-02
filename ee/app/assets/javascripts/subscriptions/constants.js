import { __, s__ } from '~/locale';

export const ZUORA_SCRIPT_URL = 'https://static.zuora.com/Resources/libs/hosted/1.3.1/zuora-min.js';

export const PAYMENT_FORM_ID = 'paid_signup_flow';

export const ZUORA_IFRAME_OVERRIDE_PARAMS = {
  style: 'inline',
  submitEnabled: 'true',
  retainValues: 'true',
};

export const ERROR_UNEXPECTED = __('An unexpected error occurred');
export const ERROR_FETCHING_COUNTRIES = s__('Checkout|Failed to load countries. Please try again.');
export const ERROR_FETCHING_STATES = s__('Checkout|Failed to load states. Please try again.');
export const ERROR_LOADING_PAYMENT_FORM = s__(
  'Checkout|Failed to load the payment form. Please try again.',
);

/* eslint-disable @gitlab/require-i18n-strings */
export const STEP_SUBSCRIPTION_DETAILS = 'subscriptionDetails';
export const STEP_BILLING_ADDRESS = 'billingAddress';
export const STEP_PAYMENT_METHOD = 'paymentMethod';
export const STEP_CONFIRM_ORDER = 'confirmOrder';

// The order of the steps in this array determines the flow of the application
export const STEPS = [
  { id: STEP_SUBSCRIPTION_DETAILS, __typename: 'Step' },
  { id: STEP_BILLING_ADDRESS, __typename: 'Step' },
  { id: STEP_PAYMENT_METHOD, __typename: 'Step' },
  { id: STEP_CONFIRM_ORDER, __typename: 'Step' },
];
export const TRACK_SUCCESS_MESSAGE = 'Success';
/* eslint-enable @gitlab/require-i18n-strings */

export const QSR_RECONCILIATION_PATH = 'subscriptions/quarterly_reconciliation.html';
