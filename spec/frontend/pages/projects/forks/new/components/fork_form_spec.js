import { GlFormInputGroup, GlFormInput, GlForm, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { getByRole, getAllByRole } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import { kebabCase } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createFlash from '~/flash';
import * as urlUtility from '~/lib/utils/url_utility';
import ForkForm from '~/pages/projects/forks/new/components/fork_form.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import searchQuery from '~/pages/projects/forks/new/queries/search_forkable_namespaces.query.graphql';
import ProjectNamespace from '~/pages/projects/forks/new/components/project_namespace.vue';

jest.mock('~/flash');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('ForkForm component', () => {
  let wrapper;
  let axiosMock;
  let mockQueryResponse;

  const PROJECT_VISIBILITY_TYPE = {
    private:
      'Private Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
    internal: 'Internal The project can be accessed by any logged in user.',
    public: 'Public The project can be accessed without any authentication.',
  };

  const GON_API_VERSION = 'v7';

  const DEFAULT_PROVIDE = {
    newGroupPath: 'some/groups/path',
    visibilityHelpPath: 'some/visibility/help/path',
    projectFullPath: '/some/project-full-path',
    projectId: '10',
    projectName: 'Project Name',
    projectPath: 'project-name',
    projectDescription: 'some project description',
    projectVisibility: 'private',
    restrictedVisibilityLevels: [],
  };

  Vue.use(VueApollo);

  const createComponentFactory = (mountFn) => (provide = {}, data = {}) => {
    const queryResponse = {
      project: {
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

    mockQueryResponse = jest.fn().mockResolvedValue({ data: queryResponse });
    const requestHandlers = [[searchQuery, mockQueryResponse]];
    const apolloProvider = createMockApollo(requestHandlers);

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: searchQuery,
      data: {
        ...queryResponse,
      },
    });

    wrapper = mountFn(ForkForm, {
      apolloProvider,
      provide: {
        ...DEFAULT_PROVIDE,
        ...provide,
      },
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        GlFormInputGroup,
        GlFormInput,
        GlFormRadioGroup,
        GlFormRadio,
      },
    });
  };

  const createComponent = createComponentFactory(shallowMount);
  const createFullComponent = createComponentFactory(mount);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    window.gon = {
      api_version: GON_API_VERSION,
    };
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  const findPrivateRadio = () => wrapper.find('[data-testid="radio-private"]');
  const findInternalRadio = () => wrapper.find('[data-testid="radio-internal"]');
  const findPublicRadio = () => wrapper.find('[data-testid="radio-public"]');
  const findForkNameInput = () => wrapper.find('[data-testid="fork-name-input"]');
  const findForkUrlInput = () => wrapper.findComponent(ProjectNamespace);
  const findForkSlugInput = () => wrapper.find('[data-testid="fork-slug-input"]');
  const findForkDescriptionTextarea = () =>
    wrapper.find('[data-testid="fork-description-textarea"]');
  const findVisibilityRadioGroup = () =>
    wrapper.find('[data-testid="fork-visibility-radio-group"]');

  it('will go to projectFullPath when click cancel button', () => {
    createComponent();

    const { projectFullPath } = DEFAULT_PROVIDE;
    const cancelButton = wrapper.find('[data-testid="cancel-button"]');

    expect(cancelButton.attributes('href')).toBe(projectFullPath);
  });

  const selectedMockNamespace = { name: 'two', full_name: 'two-group/two', id: 2 };

  const fillForm = () => {
    findForkUrlInput().vm.$emit('select', selectedMockNamespace);
  };

  it('has input with csrf token', () => {
    createComponent();

    expect(wrapper.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('pre-populate form from project props', () => {
    createComponent();

    expect(findForkNameInput().attributes('value')).toBe(DEFAULT_PROVIDE.projectName);
    expect(findForkSlugInput().attributes('value')).toBe(DEFAULT_PROVIDE.projectPath);
    expect(findForkDescriptionTextarea().attributes('value')).toBe(
      DEFAULT_PROVIDE.projectDescription,
    );
  });

  it('will have required attribute for required fields', () => {
    createComponent();

    expect(findForkNameInput().attributes('required')).not.toBeUndefined();
    expect(findForkSlugInput().attributes('required')).not.toBeUndefined();
    expect(findVisibilityRadioGroup().attributes('required')).not.toBeUndefined();
    expect(findForkDescriptionTextarea().attributes('required')).toBeUndefined();
  });

  describe('project slug', () => {
    const projectPath = 'some other project slug';

    beforeEach(() => {
      createComponent({
        projectPath,
      });
    });

    it('initially loads slug without kebab-case transformation', () => {
      expect(findForkSlugInput().attributes('value')).toBe(projectPath);
    });

    it('changes to kebab case when project name changes', async () => {
      const newInput = `${projectPath}1`;
      findForkNameInput().vm.$emit('input', newInput);
      await nextTick();

      expect(findForkSlugInput().attributes('value')).toBe(kebabCase(newInput));
    });

    it('does not change to kebab case when project slug is changed manually', async () => {
      const newInput = `${projectPath}1`;
      findForkSlugInput().vm.$emit('input', newInput);
      await nextTick();

      expect(findForkSlugInput().attributes('value')).toBe(newInput);
    });
  });

  describe('visibility level', () => {
    it('displays the correct description', () => {
      createComponent();

      const formRadios = wrapper.findAllComponents(GlFormRadio);

      Object.keys(PROJECT_VISIBILITY_TYPE).forEach((visibilityType, index) => {
        expect(formRadios.at(index).text()).toBe(PROJECT_VISIBILITY_TYPE[visibilityType]);
      });
    });

    it('displays all 3 visibility levels', () => {
      createComponent();

      expect(wrapper.findAllComponents(GlFormRadio)).toHaveLength(3);
    });

    describe('when the namespace is changed', () => {
      const namespaces = [
        {
          visibility: 'private',
        },
        {
          visibility: 'internal',
        },
        {
          visibility: 'public',
        },
      ];

      it('resets the visibility to default "private"', async () => {
        createFullComponent({ projectVisibility: 'public' }, { namespaces });

        expect(wrapper.vm.form.fields.visibility.value).toBe('public');

        fillForm();
        await nextTick();

        expect(getByRole(wrapper.element, 'radio', { name: /private/i }).checked).toBe(true);
      });

      it('sets the visibility to be null when restrictedVisibilityLevels is set', async () => {
        createFullComponent({ restrictedVisibilityLevels: [10] }, { namespaces });

        fillForm();
        await nextTick();

        const container = getByRole(wrapper.element, 'radiogroup', { name: /visibility/i });
        const visibilityRadios = getAllByRole(container, 'radio');
        expect(visibilityRadios.filter((e) => e.checked)).toHaveLength(0);
      });
    });

    it.each`
      project       | restrictedVisibilityLevels
      ${'private'}  | ${[]}
      ${'internal'} | ${[]}
      ${'public'}   | ${[]}
      ${'private'}  | ${[0]}
      ${'private'}  | ${[10]}
      ${'private'}  | ${[20]}
      ${'private'}  | ${[0, 10]}
      ${'private'}  | ${[0, 20]}
      ${'private'}  | ${[10, 20]}
      ${'private'}  | ${[0, 10, 20]}
      ${'internal'} | ${[0]}
      ${'internal'} | ${[10]}
      ${'internal'} | ${[20]}
      ${'internal'} | ${[0, 10]}
      ${'internal'} | ${[0, 20]}
      ${'internal'} | ${[10, 20]}
      ${'internal'} | ${[0, 10, 20]}
      ${'public'}   | ${[0]}
      ${'public'}   | ${[10]}
      ${'public'}   | ${[0, 10]}
      ${'public'}   | ${[0, 20]}
      ${'public'}   | ${[10, 20]}
      ${'public'}   | ${[0, 10, 20]}
    `('checks the correct radio button', ({ project, restrictedVisibilityLevels }) => {
      createFullComponent({
        projectVisibility: project,
        restrictedVisibilityLevels,
      });

      if (restrictedVisibilityLevels.length === 0) {
        expect(wrapper.find('[name="visibility"]:checked').attributes('value')).toBe(project);
      } else {
        expect(wrapper.find('[name="visibility"]:checked').exists()).toBe(false);
      }
    });

    it.each`
      project       | namespace     | privateIsDisabled | internalIsDisabled | publicIsDisabled | restrictedVisibilityLevels
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'private'}  | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'private'}  | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'internal'} | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'internal'} | ${'public'}   | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'public'}   | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'public'}   | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${undefined}       | ${undefined}     | ${[]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[0]}
      ${'internal'} | ${'internal'} | ${'true'}         | ${undefined}       | ${'true'}        | ${[0]}
      ${'public'}   | ${'public'}   | ${'true'}         | ${undefined}       | ${undefined}     | ${[0]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[10]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[10]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${undefined}     | ${[10]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${undefined}       | ${'true'}        | ${[20]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
    `(
      'sets appropriate radio button disabled state',
      ({
        project,
        namespace,
        privateIsDisabled,
        internalIsDisabled,
        publicIsDisabled,
        restrictedVisibilityLevels,
      }) => {
        createComponent(
          {
            projectVisibility: project,
            restrictedVisibilityLevels,
          },
          {
            form: { fields: { namespace: { value: { visibility: namespace } } } },
          },
        );

        expect(findPrivateRadio().attributes('disabled')).toBe(privateIsDisabled);
        expect(findInternalRadio().attributes('disabled')).toBe(internalIsDisabled);
        expect(findPublicRadio().attributes('disabled')).toBe(publicIsDisabled);
      },
    );
  });

  describe('onSubmit', () => {
    const setupComponent = (fields = {}) => {
      jest.spyOn(urlUtility, 'redirectTo').mockImplementation();

      createFullComponent(
        {},
        {
          form: {
            state: true,
            ...fields,
          },
        },
      );
    };

    beforeEach(() => {
      setupComponent();
    });

    const submitForm = async () => {
      fillForm();
      await nextTick();
      const form = wrapper.findComponent(GlForm);

      await form.trigger('submit');
      await nextTick();
    };

    describe('with invalid form', () => {
      it('does not make POST request', () => {
        jest.spyOn(axios, 'post');

        setupComponent();

        expect(axios.post).not.toHaveBeenCalled();
      });

      it('does not redirect the current page', async () => {
        setupComponent();

        await submitForm();

        expect(urlUtility.redirectTo).not.toHaveBeenCalled();
      });

      it('does not make POST request if no visbility is checked', async () => {
        jest.spyOn(axios, 'post');

        setupComponent({
          fields: {
            visibility: {
              value: null,
            },
          },
        });

        await submitForm();

        expect(axios.post).not.toHaveBeenCalled();
      });
    });

    describe('with valid form', () => {
      it('make POST request with project param', async () => {
        jest.spyOn(axios, 'post');

        setupComponent();
        await submitForm();

        const {
          projectId,
          projectDescription,
          projectName,
          projectPath,
          projectVisibility,
        } = DEFAULT_PROVIDE;

        const url = `/api/${GON_API_VERSION}/projects/${projectId}/fork`;
        const project = {
          description: projectDescription,
          id: projectId,
          name: projectName,
          namespace_id: selectedMockNamespace.id,
          path: projectPath,
          visibility: projectVisibility,
        };

        expect(axios.post).toHaveBeenCalledWith(url, project);
      });

      it('redirect to POST web_url response', async () => {
        const webUrl = `new/fork-project`;
        jest.spyOn(axios, 'post').mockResolvedValue({ data: { web_url: webUrl } });

        setupComponent();
        await submitForm();

        expect(urlUtility.redirectTo).toHaveBeenCalledWith(webUrl);
      });

      it('display flash when POST is unsuccessful', async () => {
        const dummyError = 'Fork project failed';

        jest.spyOn(axios, 'post').mockRejectedValue(dummyError);

        setupComponent();
        await submitForm();

        expect(urlUtility.redirectTo).not.toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalledWith({
          message: 'An error occurred while forking the project. Please try again.',
        });
      });
    });
  });
});
