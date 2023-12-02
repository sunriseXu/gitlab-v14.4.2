import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlTruncate,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import createFlash from '~/flash';
import searchQuery from '~/pages/projects/forks/new/queries/search_forkable_namespaces.query.graphql';
import ProjectNamespace from '~/pages/projects/forks/new/components/project_namespace.vue';

jest.mock('~/flash');

describe('ProjectNamespace component', () => {
  let wrapper;
  let originalGon;

  const data = {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      forkTargets: {
        nodes: [
          {
            id: 'gid://gitlab/Group/21',
            fullPath: 'flightjs',
            name: 'Flight JS',
            visibility: 'public',
          },
          {
            id: 'gid://gitlab/Namespace/4',
            fullPath: 'root',
            name: 'Administrator',
            visibility: 'public',
          },
        ],
      },
    },
  };

  const mockQueryResponse = jest.fn().mockResolvedValue({ data });

  const emptyQueryResponse = {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      forkTargets: {
        nodes: [],
      },
    },
  };

  const mockQueryError = jest.fn().mockRejectedValue(new Error('Network error'));

  Vue.use(VueApollo);

  const gitlabUrl = 'https://gitlab.com';

  const defaultProvide = {
    projectFullPath: 'gitlab-org/project',
  };

  const mountComponent = ({
    provide = defaultProvide,
    queryHandler = mockQueryResponse,
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [[searchQuery, queryHandler]];
    const apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ProjectNamespace, {
      apolloProvider,
      provide,
    });
  };

  const findButtonLabel = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownText = () => wrapper.findComponent(GlTruncate);
  const findInput = () => wrapper.findComponent(GlSearchBoxByType);

  const clickDropdownItem = async () => {
    wrapper.findComponent(GlDropdownItem).vm.$emit('click');
    await nextTick();
  };

  const showDropdown = () => {
    findDropdown().vm.$emit('shown');
  };

  beforeAll(() => {
    originalGon = window.gon;
    window.gon = { gitlab_url: gitlabUrl };
  });

  afterAll(() => {
    window.gon = originalGon;
    wrapper.destroy();
  });

  describe('Initial state', () => {
    beforeEach(() => {
      mountComponent({ mountFn: mount });
      jest.runOnlyPendingTimers();
    });

    it('renders the root url as a label', () => {
      expect(findButtonLabel().text()).toBe(`${gitlabUrl}/`);
      expect(findButtonLabel().props('label')).toBe(true);
    });

    it('renders placeholder text', () => {
      expect(findDropdownText().props('text')).toBe('Select a namespace');
    });
  });

  describe('After user interactions', () => {
    beforeEach(async () => {
      mountComponent({ mountFn: mount });
      jest.runOnlyPendingTimers();
      await nextTick();
      showDropdown();
    });

    it('focuses on the input when the dropdown is opened', () => {
      const spy = jest.spyOn(findInput().vm, 'focusInput');
      showDropdown();
      expect(spy).toHaveBeenCalledTimes(1);
    });

    it('displays fetched namespaces', () => {
      const listItems = wrapper.findAll('li');
      expect(listItems).toHaveLength(3);
      expect(listItems.at(0).findComponent(GlDropdownSectionHeader).text()).toBe('Namespaces');
      expect(listItems.at(1).text()).toBe(data.project.forkTargets.nodes[0].fullPath);
      expect(listItems.at(2).text()).toBe(data.project.forkTargets.nodes[1].fullPath);
    });

    it('sets the selected namespace', async () => {
      const { fullPath } = data.project.forkTargets.nodes[0];
      await clickDropdownItem();
      expect(findDropdownText().props('text')).toBe(fullPath);
    });
  });

  describe('With empty query response', () => {
    beforeEach(() => {
      mountComponent({ queryHandler: emptyQueryResponse, mountFn: mount });
      jest.runOnlyPendingTimers();
    });

    it('renders `No matches found`', () => {
      expect(wrapper.find('li').text()).toBe('No matches found');
    });
  });

  describe('With error while fetching data', () => {
    beforeEach(async () => {
      mountComponent({ queryHandler: mockQueryError });
      jest.runOnlyPendingTimers();
      await nextTick();
    });

    it('creates a flash message and captures the error', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong while loading data. Please refresh the page to try again.',
        captureError: true,
        error: expect.any(Error),
      });
    });
  });
});
