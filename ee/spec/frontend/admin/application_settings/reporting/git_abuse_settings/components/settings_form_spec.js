import { GlButton, GlForm, GlToggle } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';

import SettingsForm from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';
import UsersAllowlist from 'ee/admin/application_settings/reporting/git_abuse_settings/components/users_allowlist.vue';

import {
  NUM_REPOS_BLANK_ERROR,
  NUM_REPOS_NAN_ERROR,
  NUM_REPOS_LIMIT_ERROR,
  TIME_PERIOD_BLANK_ERROR,
  TIME_PERIOD_NAN_ERROR,
  TIME_PERIOD_LIMIT_ERROR,
  NUM_REPO_LABEL,
  NUM_REPO_DESCRIPTION,
  REPORTING_TIME_PERIOD_LABEL,
  EXCLUDED_USERS_LABEL,
  MAX_EXCLUDED_USERS,
  EXCLUDED_USERS_LIMIT_ERROR,
  AUTO_BAN_TOGGLE_LABEL,
} from 'ee/admin/application_settings/reporting/git_abuse_settings/constants';

describe('Git abuse rate limit settings form component', () => {
  let wrapper;

  const findNumberOfReposFormGroup = () => wrapper.findByTestId('number-of-repos-group');
  const findNumberOfReposInput = () => wrapper.findByTestId('number-of-repos-input');

  const findReportingTimePeriodFormGroup = () =>
    wrapper.findByTestId('reporting-time-period-group');
  const findReportingTimePeriodInput = () => wrapper.findByTestId('reporting-time-period-input');

  const findExcludedUsersFormGroup = () => wrapper.findByTestId('excluded-users-group');

  const findUsersAllowlist = () => wrapper.findComponent(UsersAllowlist);

  const findAutoBanToggle = () => wrapper.findComponent(GlToggle);

  const findSubmitButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsForm, {
      propsData: {
        isLoading: false,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Number of repositories input field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label, description and a valid state', () => {
      expect(findNumberOfReposFormGroup().attributes()).toMatchObject({
        label: NUM_REPO_LABEL,
        description: NUM_REPO_DESCRIPTION,
        state: 'true',
      });
    });

    it('should be of type number', () => {
      expect(findNumberOfReposInput().attributes('type')).toBe('number');
    });

    it('should pre-fill value from props', () => {
      createComponent({ props: { maxDownloads: 10 } });

      expect(findNumberOfReposInput().attributes('value')).toBe('10');
    });

    it.each`
      value      | valid    | errorMessage
      ${'0'}     | ${true}  | ${''}
      ${'10'}    | ${true}  | ${''}
      ${'10000'} | ${true}  | ${''}
      ${'10001'} | ${false} | ${NUM_REPOS_LIMIT_ERROR}
      ${'-1'}    | ${false} | ${NUM_REPOS_LIMIT_ERROR}
      ${''}      | ${false} | ${NUM_REPOS_BLANK_ERROR}
      ${'abc'}   | ${false} | ${NUM_REPOS_NAN_ERROR}
    `(
      'when the input has a value of $value, then its validity should be $valid',
      async ({ value, valid, errorMessage }) => {
        findNumberOfReposInput().vm.$emit('input', value);
        findNumberOfReposInput().vm.$emit('blur');

        await nextTick();

        const expectedState = valid ? 'true' : undefined;
        const expectedButtonState = valid ? undefined : 'true';

        expect(findNumberOfReposFormGroup().attributes()).toMatchObject({
          'invalid-feedback': errorMessage,
        });

        expect(findNumberOfReposFormGroup().attributes('state')).toBe(expectedState);

        expect(findNumberOfReposInput().classes('is-invalid')).toBe(!valid);

        expect(findSubmitButton().attributes('disabled')).toBe(expectedButtonState);
      },
    );
  });

  describe('Reporting time period input field', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should have label and a valid state', () => {
      expect(findReportingTimePeriodFormGroup().attributes()).toMatchObject({
        label: REPORTING_TIME_PERIOD_LABEL,
        state: 'true',
      });
    });

    it('should be of type number', () => {
      expect(findReportingTimePeriodInput().attributes('type')).toBe('number');
    });

    it('should pre-fill value from props', () => {
      createComponent({ props: { timePeriod: 100 } });

      expect(findReportingTimePeriodInput().attributes('value')).toBe('100');
    });

    it.each`
      value       | valid    | errorMessage
      ${'0'}      | ${true}  | ${''}
      ${'600'}    | ${true}  | ${''}
      ${'864000'} | ${true}  | ${''}
      ${'864001'} | ${false} | ${TIME_PERIOD_LIMIT_ERROR}
      ${'-1'}     | ${false} | ${TIME_PERIOD_LIMIT_ERROR}
      ${''}       | ${false} | ${TIME_PERIOD_BLANK_ERROR}
      ${'abc'}    | ${false} | ${TIME_PERIOD_NAN_ERROR}
    `(
      'when the input has a value of $value, then its validity should be $valid',
      async ({ value, valid, errorMessage }) => {
        findReportingTimePeriodInput().vm.$emit('input', value);
        findReportingTimePeriodInput().vm.$emit('blur');

        await nextTick();

        const expectedState = valid ? 'true' : undefined;
        const expectedButtonState = valid ? undefined : 'true';

        expect(findReportingTimePeriodFormGroup().attributes()).toMatchObject({
          'invalid-feedback': errorMessage,
        });

        expect(findReportingTimePeriodFormGroup().attributes('state')).toBe(expectedState);

        expect(findReportingTimePeriodInput().classes('is-invalid')).toBe(!valid);

        expect(findSubmitButton().attributes('disabled')).toBe(expectedButtonState);
      },
    );
  });

  describe('Excluded Users input field', () => {
    it('should have label and a valid state', () => {
      createComponent();

      expect(findExcludedUsersFormGroup().attributes()).toMatchObject({
        label: EXCLUDED_USERS_LABEL,
        state: 'true',
      });
    });

    it('should render UsersAllowlist component', () => {
      createComponent();

      expect(findUsersAllowlist().exists()).toBe(true);
      expect(findUsersAllowlist().props('excludedUsernames')).toEqual([]);
    });

    it('should pass the correct props to UsersAllowlist component', () => {
      createComponent({ props: { allowlist: ['user1', 'user2'] } });

      expect(findUsersAllowlist().props('excludedUsernames')).toEqual(['user1', 'user2']);
    });

    it('should add user to data when user-added event is emitted', () => {
      createComponent();

      findUsersAllowlist().vm.$emit('user-added', 'user1');

      expect(wrapper.vm.excludedUsers).toEqual(['user1']);
    });

    it('should remove user from data when user-removed event is emitted', () => {
      createComponent({ props: { allowlist: ['user1', 'user2'] } });

      findUsersAllowlist().vm.$emit('user-removed', 'user1');

      expect(wrapper.vm.excludedUsers).toEqual(['user2']);
    });

    describe('validation', () => {
      beforeEach(async () => {
        createComponent();

        for (let i = 1; i <= MAX_EXCLUDED_USERS; i += 1) {
          findUsersAllowlist().vm.$emit('user-added', `user${i}`);
        }

        await nextTick();
      });

      it('should be valid with a 100 users', () => {
        expect(findExcludedUsersFormGroup().attributes()).toMatchObject({
          'invalid-feedback': '',
          state: 'true',
        });
      });

      it('should be invalid 101 users', async () => {
        findUsersAllowlist().vm.$emit('user-added', 'user101');
        await nextTick();

        expect(findExcludedUsersFormGroup().attributes()).toMatchObject({
          'invalid-feedback': EXCLUDED_USERS_LIMIT_ERROR,
        });

        expect(findExcludedUsersFormGroup().attributes('state')).toBe(undefined);

        expect(findSubmitButton().attributes('disabled')).toBe('true');
      });
    });
  });

  describe('Auto ban users toggle', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders component properly', () => {
      expect(findAutoBanToggle().exists()).toBe(true);
    });

    it('shows the toggle component', () => {
      expect(findAutoBanToggle().props('label')).toBe(
        sprintf(AUTO_BAN_TOGGLE_LABEL, { scope: 'application' }),
      );
    });

    it('sets the default value to be false', () => {
      expect(findAutoBanToggle().props('value')).toBe(false);
    });

    it('emits toggle event', async () => {
      findAutoBanToggle().vm.$emit('change', true);

      await nextTick();

      expect(findAutoBanToggle().props('value')).toBe(true);
    });
  });

  describe('Form submission', () => {
    it('emits "submit" event with the correct arguments when form is submitted', () => {
      createComponent({ props: { timePeriod: 1, allowlist: ['user1'], autoBanUsers: true } });

      wrapper.findComponent(GlForm).vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      const submitEvents = wrapper.emitted().submit;
      expect(submitEvents.length).toEqual(1);
      expect(submitEvents[0][0]).toMatchObject({
        maxDownloads: 0,
        timePeriod: 1,
        allowlist: ['user1'],
        autoBanUsers: true,
      });
    });
  });
});
