import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from '~/packages_and_registries/settings/project/components/cleanup_image_tags.vue';
import ContainerExpirationPolicyForm from '~/packages_and_registries/settings/project/components/container_expiration_policy_form.vue';
import {
  CONTAINER_CLEANUP_POLICY_TITLE,
  CONTAINER_CLEANUP_POLICY_DESCRIPTION,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UNAVAILABLE_FEATURE_INTRO_TEXT,
  UNAVAILABLE_USER_FEATURE_TEXT,
} from '~/packages_and_registries/settings/project/constants';
import expirationPolicyQuery from '~/packages_and_registries/settings/project/graphql/queries/get_expiration_policy.query.graphql';

import {
  expirationPolicyPayload,
  emptyExpirationPolicyPayload,
  containerExpirationPolicyData,
} from '../mock_data';

describe('Cleanup image tags project settings', () => {
  let wrapper;
  let fakeApollo;

  const defaultProvidedValues = {
    projectPath: 'path',
    isAdmin: false,
    adminSettingsPath: 'settingsPath',
    enableHistoricEntries: false,
    helpPagePath: 'helpPagePath',
    showCleanupPolicyLink: false,
  };

  const findFormComponent = () => wrapper.findComponent(ContainerExpirationPolicyForm);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');

  const mountComponent = (provide = defaultProvidedValues, config) => {
    wrapper = shallowMountExtended(component, {
      stubs: {
        GlSprintf,
      },
      provide,
      ...config,
    });
  };

  const mountComponentWithApollo = ({ provide = defaultProvidedValues, resolver } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[expirationPolicyQuery, resolver]];

    fakeApollo = createMockApollo(requestHandlers);
    mountComponent(provide, {
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('isEdited status', () => {
    it.each`
      description                                  | apiResponse                       | workingCopy                                                   | result
      ${'empty response and no changes from user'} | ${emptyExpirationPolicyPayload()} | ${{}}                                                         | ${false}
      ${'empty response and changes from user'}    | ${emptyExpirationPolicyPayload()} | ${{ enabled: true }}                                          | ${true}
      ${'response and no changes'}                 | ${expirationPolicyPayload()}      | ${containerExpirationPolicyData()}                            | ${false}
      ${'response and changes'}                    | ${expirationPolicyPayload()}      | ${{ ...containerExpirationPolicyData(), nameRegex: '12345' }} | ${true}
      ${'response and empty'}                      | ${expirationPolicyPayload()}      | ${{}}                                                         | ${true}
    `('$description', async ({ apiResponse, workingCopy, result }) => {
      mountComponentWithApollo({
        provide: { ...defaultProvidedValues, enableHistoricEntries: true },
        resolver: jest.fn().mockResolvedValue(apiResponse),
      });
      await waitForPromises();

      findFormComponent().vm.$emit('input', workingCopy);

      await waitForPromises();

      expect(findFormComponent().props('isEdited')).toBe(result);
    });
  });

  it('renders the setting form', async () => {
    mountComponentWithApollo({
      resolver: jest.fn().mockResolvedValue(expirationPolicyPayload()),
    });
    await waitForPromises();

    expect(findFormComponent().exists()).toBe(true);
    expect(findTitle().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_TITLE);
    expect(findDescription().text()).toMatchInterpolatedText(CONTAINER_CLEANUP_POLICY_DESCRIPTION);
  });

  describe('the form is disabled', () => {
    it('hides the form', () => {
      mountComponent();

      expect(findFormComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      mountComponent();

      const text = findAlert().text();
      expect(text).toContain(UNAVAILABLE_FEATURE_INTRO_TEXT);
      expect(text).toContain(UNAVAILABLE_USER_FEATURE_TEXT);
    });

    describe('an admin is visiting the page', () => {
      it('shows the admin part of the alert message', () => {
        mountComponent({ ...defaultProvidedValues, isAdmin: true });

        const sprintf = findAlert().findComponent(GlSprintf);
        expect(sprintf.text()).toBe('administration settings');
        expect(sprintf.findComponent(GlLink).attributes('href')).toBe(
          defaultProvidedValues.adminSettingsPath,
        );
      });
    });
  });

  describe('fetchSettingsError', () => {
    beforeEach(async () => {
      mountComponentWithApollo({
        resolver: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      await waitForPromises();
    });

    it('hides the form', () => {
      expect(findFormComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      expect(findAlert().html()).toContain(FETCH_SETTINGS_ERROR_MESSAGE);
    });
  });

  describe('empty API response', () => {
    it.each`
      enableHistoricEntries | isShown
      ${true}               | ${true}
      ${false}              | ${false}
    `('is $isShown that the form is shown', async ({ enableHistoricEntries, isShown }) => {
      mountComponentWithApollo({
        provide: {
          ...defaultProvidedValues,
          enableHistoricEntries,
        },
        resolver: jest.fn().mockResolvedValue(emptyExpirationPolicyPayload()),
      });
      await waitForPromises();

      expect(findFormComponent().exists()).toBe(isShown);
    });
  });
});
