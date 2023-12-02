import {
  GlDropdownDivider,
  GlDropdownItem,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import IterationDropdown from 'ee/sidebar/components/iteration_dropdown.vue';
import groupIterationsQuery from 'ee/sidebar/queries/iterations.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getIterationPeriod } from 'ee/iterations/utils';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';

Vue.use(VueApollo);

const TEST_SEARCH = 'search';
const TEST_FULL_PATH = 'gitlab-test/test';
const TEST_ITERATIONS = [
  {
    __typename: 'Iteration',
    id: '11',
    title: 'Test Title',
    startDate: '2021-10-01',
    dueDate: '2021-10-05',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '111',
      title: 'My Cadence',
    },
  },
  {
    __typename: 'Iteration',
    id: '22',
    title: null,
    startDate: '2021-10-06',
    dueDate: '2021-10-10',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '222',
      title: 'My Second Cadence',
    },
  },
  {
    __typename: 'Iteration',
    id: '33',
    title: null,
    startDate: '2021-10-11',
    dueDate: '2021-10-15',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '333',
      title: 'My Cadence',
    },
  },
];

describe('IterationDropdown', () => {
  let wrapper;
  let fakeApollo;
  let groupIterationsSpy;

  beforeEach(() => {
    groupIterationsSpy = jest.fn().mockResolvedValue({
      data: {
        group: {
          __typename: 'Group',
          id: '1',
          iterations: {
            nodes: TEST_ITERATIONS.map((iteration) => ({ ...iteration, __typename: 'Iteration' })),
          },
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const waitForDebounce = async () => {
    await nextTick();
    jest.runOnlyPendingTimers();
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemsAt = (i) => findDropdownItems().at(i);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.text().includes(text));
  const selectDropdownItemAndWait = async (text) => {
    const item = findDropdownItemWithText(text);

    item.vm.$emit('click');

    await nextTick();
  };
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const showDropdownAndWait = async () => {
    findDropdown().vm.$emit('show');

    await waitForDebounce();
  };
  const isLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const createComponent = ({ mountFn = shallowMount, iterationCadences = false } = {}) => {
    fakeApollo = createMockApollo([[groupIterationsQuery, groupIterationsSpy]]);

    wrapper = mountFn(IterationDropdown, {
      apolloProvider: fakeApollo,
      propsData: {
        fullPath: TEST_FULL_PATH,
      },
      stubs: {
        IterationTitle,
      },
      provide: {
        glFeatures: {
          iterationCadences,
        },
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show loading', () => {
      expect(isLoading()).toBe(false);
    });

    it('shows gl-dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdown().element).toMatchSnapshot();
    });
  });

  describe('when dropdown opens and query is loading', () => {
    beforeEach(async () => {
      // return promise that doesn't resolve to force loading state
      groupIterationsSpy.mockReturnValue(new Promise(() => {}));

      createComponent();

      await showDropdownAndWait();
    });

    it('shows loading', () => {
      expect(isLoading()).toBe(true);
    });

    it('calls groupIterations query', () => {
      expect(groupIterationsSpy).toHaveBeenCalledTimes(1);
      expect(groupIterationsSpy).toHaveBeenCalledWith({
        fullPath: TEST_FULL_PATH,
        state: 'opened',
        title: '',
      });
    });
  });

  describe('when dropdown opens and query responds', () => {
    beforeEach(async () => {
      createComponent();

      await showDropdownAndWait();
    });

    it('does not show loading', () => {
      expect(isLoading()).toBe(false);
    });

    it('shows checkable dropdown items in unchecked state', () => {
      expect(findDropdownItems().wrappers.every((x) => x.props('isCheckItem'))).toBe(true);
      expect(findDropdownItems().wrappers.every((x) => x.props('isChecked'))).toBe(false);
    });

    it('populates dropdown items with correct names', () => {
      // "No iteration" dropdown item
      expect(findDropdownItemsAt(0).text()).toContain(IterationDropdown.noIteration.text);

      // Iteration with title
      expect(findDropdownItemsAt(1).text()).toContain(getIterationPeriod(TEST_ITERATIONS[0]));
      expect(findDropdownItemsAt(1).text()).toContain(TEST_ITERATIONS[0].title);

      // Iteration without title
      expect(findDropdownItemsAt(2).text()).toContain(getIterationPeriod(TEST_ITERATIONS[1]));
    });

    it('does not re-query if opened again', async () => {
      groupIterationsSpy.mockClear();
      await showDropdownAndWait();

      expect(groupIterationsSpy).not.toHaveBeenCalled();
    });

    describe.each([
      {
        text: IterationDropdown.noIteration.text,
        dropdownText: 'Select iteration',
        iteration: IterationDropdown.noIteration,
      },
      {
        text: getIterationPeriod(TEST_ITERATIONS[0]),
        dropdownText: getIterationPeriod(TEST_ITERATIONS[0]),
        iteration: TEST_ITERATIONS[0],
      },
      {
        text: getIterationPeriod(TEST_ITERATIONS[1]),
        dropdownText: getIterationPeriod(TEST_ITERATIONS[1]),
        iteration: TEST_ITERATIONS[1],
      },
    ])("when iteration '%s' is selected", ({ text, dropdownText, iteration }) => {
      beforeEach(async () => {
        await selectDropdownItemAndWait(text);
      });

      it('shows item as checked with text and emits event', () => {
        expect(findDropdown().props('text')).toBe(dropdownText);
        expect(findDropdownItemWithText(text).props('isChecked')).toBe(true);
        expect(wrapper.emitted('onIterationSelect')).toEqual([[iteration]]);
      });

      describe('when item is clicked again', () => {
        beforeEach(async () => {
          await selectDropdownItemAndWait(text);
        });

        it('shows item as unchecked', () => {
          expect(findDropdownItems().wrappers.every((x) => x.props('isChecked'))).toBe(false);
        });

        it('emits event', () => {
          expect(wrapper.emitted('onIterationSelect').length).toBe(2);
          expect(wrapper.emitted('onIterationSelect')[1]).toEqual([null]);
        });
      });
    });
  });

  describe('when dropdown opens and search is set', () => {
    beforeEach(async () => {
      createComponent();

      await showDropdownAndWait();

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', TEST_SEARCH);

      await waitForDebounce();
    });

    it('adds the search to the query', () => {
      expect(groupIterationsSpy).toHaveBeenCalledWith({
        fullPath: TEST_FULL_PATH,
        state: 'opened',
        title: `"${TEST_SEARCH}"`,
      });
    });
  });

  describe('when iteration_cadences feature flag is on', () => {
    beforeEach(async () => {
      createComponent({ iterationCadences: true, mountFn: mount });

      await showDropdownAndWait();
    });

    it('shows dropdown items grouped by iteration cadence', () => {
      const dropdownItems = wrapper.findAll('li');

      expect(dropdownItems.at(0).text()).toBe('Assign Iteration');
      expect(dropdownItems.at(1).text()).toContain('No iteration');

      expect(dropdownItems.at(2).findComponent(GlDropdownDivider).exists()).toBe(true);
      expect(dropdownItems.at(3).findComponent(GlDropdownSectionHeader).text()).toBe('My Cadence');
      expect(dropdownItems.at(4).text()).toContain(getIterationPeriod(TEST_ITERATIONS[0]));
      expect(dropdownItems.at(4).text()).toContain('Test Title');
      expect(dropdownItems.at(5).text()).toContain(getIterationPeriod(TEST_ITERATIONS[2]));

      expect(dropdownItems.at(6).findComponent(GlDropdownDivider).exists()).toBe(true);
      expect(dropdownItems.at(7).findComponent(GlDropdownSectionHeader).text()).toBe(
        'My Second Cadence',
      );
      expect(dropdownItems.at(8).text()).toContain(getIterationPeriod(TEST_ITERATIONS[1]));
    });
  });
});
