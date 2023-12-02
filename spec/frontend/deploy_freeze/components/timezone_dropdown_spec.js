import { GlDropdownItem, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import createStore from '~/deploy_freeze/store';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { findTzByName, formatTz, timezoneDataFixture } from '../helpers';

Vue.use(Vuex);

describe('Deploy freeze timezone dropdown', () => {
  let wrapper;
  let store;

  const createComponent = (searchTerm, selectedTimezone) => {
    store = createStore({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    wrapper = shallowMount(TimezoneDropdown, {
      store,
      propsData: {
        value: selectedTimezone,
        timezoneData: timezoneDataFixture,
      },
    });

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({ searchTerm });
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('No time zones found', () => {
    beforeEach(() => {
      createComponent('UTC timezone');
    });

    it('renders empty results message', () => {
      expect(findDropdownItemByIndex(0).text()).toBe('No matching results');
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('renders all timezones when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(timezoneDataFixture.length);
    });
  });

  describe('Time zones found', () => {
    beforeEach(() => {
      createComponent('Alaska');
    });

    it('renders only the time zone searched for', () => {
      const selectedTz = findTzByName('Alaska');
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe(formatTz(selectedTz));
    });

    it('should not display empty results message', () => {
      expect(wrapper.find('[data-testid="noMatchingResults"]').exists()).toBe(false);
    });

    describe('Custom events', () => {
      const selectedTz = findTzByName('Alaska');

      it('should emit input if a time zone is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');
        expect(wrapper.emitted('input')).toEqual([
          [
            {
              formattedTimezone: formatTz(selectedTz),
              identifier: selectedTz.identifier,
            },
          ],
        ]);
      });
    });
  });

  describe('Selected time zone', () => {
    beforeEach(() => {
      createComponent('', 'Alaska');
    });

    it('renders selected time zone as dropdown label', () => {
      expect(wrapper.findComponent(GlDropdown).vm.text).toBe('Alaska');
    });
  });
});
