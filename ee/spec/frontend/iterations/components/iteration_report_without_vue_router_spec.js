import { GlDropdown, GlDropdownItem, GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import IterationForm from 'ee/iterations/components/iteration_form_without_vue_router.vue';
import IterationReportTabs from 'ee/iterations/components/iteration_report_tabs.vue';
import IterationReport from 'ee/iterations/components/iteration_report_without_vue_router.vue';
import { Namespace } from 'ee/iterations/constants';
import query from 'ee/iterations/queries/iteration.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getIterationPeriod } from 'ee/iterations/utils';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';
import {
  mockIterationNode,
  mockIterationNodeWithoutTitle,
  createMockGroupIterations,
  mockProjectIterations,
} from '../mock_data';

const localVue = createLocalVue();

describe('Iterations report', () => {
  let wrapper;
  let mockApollo;

  const defaultProps = {
    fullPath: 'gitlab-org',
    labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json?include_ancestor_groups=true',
  };

  const findTopbar = () => wrapper.findComponent({ ref: 'topbar' });
  const findHeading = () => wrapper.findComponent({ ref: 'heading' });
  const findDescription = () => wrapper.findComponent({ ref: 'description' });
  const findActionsDropdown = () => wrapper.find('[data-testid="actions-dropdown"]');
  const clickEditButton = () => {
    findActionsDropdown().vm.$emit('click');
    wrapper.findComponent(GlDropdownItem).vm.$emit('click');
  };
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findIterationForm = () => wrapper.findComponent(IterationForm);

  const mountComponentWithApollo = ({
    props = defaultProps,
    iterationQueryHandler = jest.fn(),
  } = {}) => {
    localVue.use(VueApollo);
    mockApollo = createMockApollo([[query, iterationQueryHandler]]);

    wrapper = shallowMount(IterationReport, {
      localVue,
      apolloProvider: mockApollo,
      propsData: props,
      provide: {
        fullPath: props.fullPath,
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
        IterationTitle,
      },
    });
  };

  describe('with mock apollo', () => {
    describe.each([
      [
        Namespace.Group,
        'group-name',
        mockIterationNodeWithoutTitle,
        createMockGroupIterations(mockIterationNodeWithoutTitle),
      ],
      [
        Namespace.Group,
        'group-name',
        mockIterationNode,
        createMockGroupIterations(mockIterationNode),
      ],
      [Namespace.Project, 'group-name/project-name', mockIterationNode, mockProjectIterations],
    ])(
      'when viewing an iteration in a %s',
      (namespaceType, fullPath, mockIteration, mockIterations) => {
        let iterationQueryHandler;

        beforeEach(() => {
          iterationQueryHandler = jest.fn().mockResolvedValue(mockIterations);

          mountComponentWithApollo({
            props: {
              namespaceType,
              fullPath,
              iterationId: String(getIdFromGraphQLId(mockIteration.id)),
            },
            iterationQueryHandler,
          });
        });

        it('calls a query with correct parameters', () => {
          expect(iterationQueryHandler).toHaveBeenNthCalledWith(1, {
            fullPath,
            id: mockIteration.id,
            isGroup: namespaceType === Namespace.Group,
          });
        });

        it('renders iteration dates optionally with title', async () => {
          await waitForPromises();

          expect(findHeading().text()).toContain(getIterationPeriod(mockIteration));

          if (mockIteration.title) expect(findHeading().text()).toContain(mockIteration.title);
        });
      },
    );
  });

  const mountComponent = ({ props = defaultProps, loading = false } = {}) => {
    wrapper = shallowMount(IterationReport, {
      propsData: props,
      mocks: {
        $apollo: {
          queries: { iteration: { loading } },
        },
      },
      provide: {
        fullPath: props.fullPath,
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows spinner while loading', () => {
    mountComponent({
      loading: true,
    });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('empty state', () => {
    it('shows empty state if no item loaded', () => {
      mountComponent({
        loading: false,
      });

      expect(findEmptyState().props('title')).toBe('Could not find iteration');
      expect(findHeading().exists()).toBe(false);
      expect(findDescription().exists()).toBe(false);
      expect(findActionsDropdown().exists()).toBe(false);
    });
  });

  describe('item loaded', () => {
    const iteration = {
      title: null,
      id: 'gid://gitlab/Iteration/2',
      descriptionHtml: 'The first week of June',
      startDate: '2020-06-02',
      dueDate: '2020-06-08',
      state: 'opened',
    };

    describe('user without edit permission', () => {
      beforeEach(() => {
        mountComponent({
          loading: false,
        });

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          iteration,
        });
      });

      it('shows status and date in header', () => {
        expect(findTopbar().text()).toContain('Open');
        expect(findTopbar().text()).toContain('Jun 2, 2020');
        expect(findTopbar().text()).toContain('Jun 8, 2020');
      });

      it('hides empty region and loading spinner', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(false);
      });

      it('shows period and description', () => {
        expect(findHeading().text()).toContain('Jun 2, 2020 - Jun 8, 2020');
        expect(findDescription().text()).toContain(iteration.descriptionHtml);
      });

      it('hides actions dropdown', () => {
        expect(findActionsDropdown().exists()).toBe(false);
      });

      it('shows IterationReportTabs component', () => {
        const iterationReportTabs = wrapper.findComponent(IterationReportTabs);

        expect(iterationReportTabs.props()).toMatchObject({
          fullPath: defaultProps.fullPath,
          iterationId: iteration.id,
          labelsFetchPath: defaultProps.labelsFetchPath,
          namespaceType: Namespace.Group,
        });
      });
    });

    describe('user with edit permission', () => {
      describe('loading report view', () => {
        beforeEach(() => {
          mountComponent({
            props: {
              ...defaultProps,
              canEdit: true,
            },
            loading: false,
          });

          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            iteration,
          });
        });

        it('updates URL when loading form', async () => {
          jest.spyOn(window.history, 'pushState').mockImplementation(() => {});

          clickEditButton();

          await nextTick();

          expect(window.history.pushState).toHaveBeenCalledWith(
            { prev: 'viewIteration' },
            null,
            '/edit',
          );
        });
      });

      describe('loading edit form directly', () => {
        beforeEach(() => {
          mountComponent({
            props: {
              ...defaultProps,
              canEdit: true,
              initiallyEditing: true,
            },
            loading: false,
          });

          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            iteration,
          });
        });

        it('updates URL when cancelling form submit', async () => {
          jest.spyOn(window.history, 'pushState').mockImplementation(() => {});
          findIterationForm().vm.$emit('cancel');

          await nextTick();

          expect(window.history.pushState).toHaveBeenCalledWith(
            { prev: 'editIteration' },
            null,
            '/',
          );
        });

        it('updates URL after form submitted', async () => {
          jest.spyOn(window.history, 'pushState').mockImplementation(() => {});
          findIterationForm().vm.$emit('updated');

          await nextTick();

          expect(window.history.pushState).toHaveBeenCalledWith(
            { prev: 'editIteration' },
            null,
            '/',
          );
        });
      });
    });

    describe('actions dropdown to edit iteration', () => {
      describe.each`
        description                    | canEdit  | namespaceType        | canEditIteration
        ${'has permissions'}           | ${true}  | ${Namespace.Group}   | ${true}
        ${'has permissions'}           | ${true}  | ${Namespace.Project} | ${false}
        ${'does not have permissions'} | ${false} | ${Namespace.Group}   | ${false}
        ${'does not have permissions'} | ${false} | ${Namespace.Project} | ${false}
      `(
        'when user $description and they are viewing an iteration within a $namespaceType',
        ({ canEdit, namespaceType, canEditIteration }) => {
          beforeEach(() => {
            mountComponent({
              props: {
                ...defaultProps,
                canEdit,
                namespaceType,
              },
            });

            // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
            // eslint-disable-next-line no-restricted-syntax
            wrapper.setData({
              iteration,
            });
          });

          it(`${canEditIteration ? 'is shown' : 'is hidden'}`, () => {
            expect(wrapper.findComponent(GlDropdown).exists()).toBe(canEditIteration);
          });
        },
      );
    });
  });
});
