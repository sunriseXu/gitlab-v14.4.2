import { GlFormRadio, GlLink, GlFormSelect, GlFormInput, GlFormGroup } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import FormGroup from 'ee/admin/application_settings/deletion_protection/components/form_group.vue';
import { I18N_DELETION_PROTECTION } from 'ee/admin/application_settings/deletion_protection/constants';

describe('Form group component', () => {
  let wrapper;

  const DELAY_DISABLED = false;
  const DELAY_ENABLED = true;

  const findHelpText = () => wrapper.findByTestId('help-text');
  const findDeleteImmediatelyRadioButton = () => wrapper.findByTestId('delete-immediately');
  const findKeepDeleted = () => wrapper.findByTestId('keep-deleted');
  const findKeepDeletedRadioButton = () => findKeepDeleted().findComponent(GlFormRadio);
  const findSelectProjectRemoval = () => findKeepDeleted().findComponent(GlFormSelect);
  const findSelectedIndex = () => findSelectProjectRemoval().find('select').element.selectedIndex;
  const findAdjournedPeriodInput = () => findKeepDeleted().findComponent(GlFormInput);
  const findHiddenInput = () => wrapper.findByTestId('hidden-input');
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);

  const createComponent = (mountFn = shallowMountExtended, props = {}) => {
    wrapper = mountFn(FormGroup, {
      propsData: {
        deletionAdjournedPeriod: 7,
        delayedGroupDeletion: false,
        delayedProjectDeletion: false,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Heading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the form group label', () => {
      expect(findGlFormGroup().attributes('label')).toBe(I18N_DELETION_PROTECTION.heading);
    });

    it('displays the help text', () => {
      expect(findHelpText().text()).toContain(I18N_DELETION_PROTECTION.helpText);
    });

    it('displays the help link', () => {
      expect(findGlLink().text()).toContain(I18N_DELETION_PROTECTION.learnMore);
      expect(findGlLink().attributes('href')).toBe(
        helpPagePath('user/admin_area/settings/visibility_and_access_controls', {
          anchor: 'delayed-project-deletion',
        }),
      );
    });
  });

  describe('Form inputs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an input for enabling delayed group deletion', () => {
      expect(findKeepDeletedRadioButton().attributes('name')).toBe(
        'application_setting[delayed_group_deletion]',
      );
    });

    it('renders an input for disabling delayed group deletion', () => {
      expect(findDeleteImmediatelyRadioButton().attributes('name')).toBe(
        'application_setting[delayed_group_deletion]',
      );
    });

    it('renders an input for selecting delayed project deletion', () => {
      expect(findSelectProjectRemoval().attributes('name')).toBe(
        'application_setting[delayed_project_deletion]',
      );
    });

    it('renders an input for setting the deletion adjourned period', () => {
      expect(findAdjournedPeriodInput().attributes()).toMatchObject({
        name: 'application_setting[deletion_adjourned_period]',
        type: 'number',
        min: '1',
        max: '90',
      });
    });

    it('renders a hidden input for disabling delayed project deletion', () => {
      expect(findHiddenInput().attributes()).toMatchObject({
        name: 'application_setting[delayed_project_deletion]',
        value: 'false',
      });
    });
  });

  describe('Select options', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('renders the select delayed project deletion options', () => {
      const options = findSelectProjectRemoval().findAll('option');
      expect(options.at(0).text()).toBe(I18N_DELETION_PROTECTION.groupsOnly);
      expect(options.at(1).text()).toBe(I18N_DELETION_PROTECTION.groupsAndProjects);
    });
  });

  describe('When group and project delayed deletion is disabled', () => {
    it('selects the "None, delete immediately" radio button', () => {
      createComponent();

      expect(findDeleteImmediatelyRadioButton().props()).toMatchObject({ checked: DELAY_DISABLED });
    });

    it('disables the "Keep deleted" input fields', () => {
      createComponent();

      expect(findSelectProjectRemoval().attributes('disabled')).toBe('true');
      expect(findAdjournedPeriodInput().attributes('disabled')).toBe('true');
    });

    it('selects the "groups only" option', () => {
      createComponent(mountExtended);

      expect(findSelectedIndex()).toBe(0);
    });
  });

  describe('When group delayed deletion is enabled', () => {
    beforeEach(() => {
      createComponent(shallowMountExtended, { delayedGroupDeletion: true });
    });

    it('selects the "Keep deleted" radio button', () => {
      expect(findKeepDeletedRadioButton().props()).toMatchObject({ checked: DELAY_ENABLED });
    });

    it('the "Keep deleted" input fields should not be disabled', () => {
      expect(findSelectProjectRemoval().attributes('disabled')).toBeUndefined();
      expect(findAdjournedPeriodInput().attributes('disabled')).toBeUndefined();
    });
  });

  describe('When group and project delayed deletion is enabled', () => {
    beforeEach(() => {
      createComponent(mountExtended, { delayedGroupDeletion: true, delayedProjectDeletion: true });
    });

    it('selects the "Keep deleted" radio button', () => {
      expect(findKeepDeletedRadioButton().props()).toMatchObject({ checked: DELAY_ENABLED });
    });

    it('selects the "groups and projects" option', () => {
      expect(findSelectedIndex()).toBe(1);
    });

    it('does not render the hidden input', () => {
      expect(findHiddenInput().exists()).toBe(false);
    });
  });
});
