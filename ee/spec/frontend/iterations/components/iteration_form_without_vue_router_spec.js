import { GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import { nextTick } from 'vue';
import IterationForm from 'ee/iterations/components/iteration_form_without_vue_router.vue';
import createIteration from 'ee/iterations/queries/create_iteration.mutation.graphql';
import updateIteration from 'ee/iterations/queries/update_iteration.mutation.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import { formatDate } from '~/lib/utils/datetime_utility';

jest.mock('~/lib/utils/url_utility');

describe('Iteration Form', () => {
  let wrapper;
  const groupPath = 'gitlab-org';
  const id = 72;
  const iteration = {
    id: `gid://gitlab/Iteration/${id}`,
    title: 'An iteration',
    description: 'The words',
    startDate: '2020-06-28',
    dueDate: '2020-07-05',
  };

  const title = 'Updated title';
  const description = 'Updated description';
  const startDate = '2020-05-06';
  const dueDate = '2020-05-26';

  const createMutationSuccess = { data: { createIteration: { iteration, errors: [] } } };
  const createMutationFailure = {
    data: { createIteration: { iteration, errors: ['alas, your data is unchanged'] } },
  };
  const updateMutationSuccess = { data: { updateIteration: { iteration, errors: [] } } };
  const updateMutationFailure = {
    data: { updateIteration: { iteration: {}, errors: ['alas, your data is unchanged'] } },
  };
  const defaultProps = { groupPath, iterationsListPath: TEST_HOST };

  function createComponent({ mutationResult = createMutationSuccess, props = defaultProps } = {}) {
    wrapper = shallowMount(IterationForm, {
      propsData: props,
      stubs: {
        ApolloMutation,
        MarkdownField: { template: '<div><slot name="textarea"></slot></div>' },
      },
      mocks: {
        $apollo: {
          mutate: jest.fn().mockResolvedValue(mutationResult),
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findPageTitle = () => wrapper.findComponent({ ref: 'pageTitle' });
  const findTitle = () => wrapper.find('#iteration-title');
  const findDescription = () => wrapper.find('#iteration-description');
  const findStartDate = () => wrapper.find('#iteration-start-date');
  const findDueDate = () => wrapper.find('#iteration-due-date');
  const findSaveButton = () => wrapper.find('[data-testid="save-iteration"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-iteration"]');
  const clickSave = () => findSaveButton().vm.$emit('click');
  const clickCancel = () => findCancelButton().vm.$emit('click');

  const toDateString = (date) => formatDate(date, 'yyyy-mm-dd');

  const inputFormData = () => {
    findTitle().vm.$emit('input', title);
    findDescription().setValue(description);
    findStartDate().vm.$emit('input', startDate ? new Date(startDate) : null);
    findDueDate().vm.$emit('input', dueDate ? new Date(dueDate) : null);

    findTitle().trigger('change');
    findStartDate().trigger('change');
  };

  it('renders a form', () => {
    createComponent();
    expect(wrapper.findComponent(GlForm).exists()).toBe(true);
  });

  describe('New iteration', () => {
    beforeEach(() => {
      createComponent();
    });

    it('cancel button links to list page', () => {
      clickCancel();

      expect(visitUrl).toHaveBeenCalledWith(TEST_HOST);
    });

    describe('save', () => {
      it('triggers mutation with form data', () => {
        inputFormData();
        clickSave();

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createIteration,
          variables: {
            input: {
              groupPath,
              title,
              description,
              startDate,
              dueDate,
            },
          },
        });
      });

      it('redirects to Iteration page on success', async () => {
        createComponent();
        inputFormData();
        clickSave();

        await nextTick();
        expect(findSaveButton().props('loading')).toBe(true);
        expect(visitUrl).toHaveBeenCalled();
      });

      it('validates required fields and sets isValid state to false', async () => {
        createComponent();

        clickSave();

        await nextTick();

        expect(findSaveButton().props('loading')).toBe(false);
        expect(wrapper.vm.isValid).toBe(false);
        expect(wrapper.vm.titleState).toBe(false);
        expect(wrapper.vm.startDateState).toBe(false);
        expect(visitUrl).not.toHaveBeenCalled();
      });

      it('loading=false on error', () => {
        createComponent({ mutationResult: createMutationFailure });

        clickSave();

        return waitForPromises().then(() => {
          expect(findSaveButton().props('loading')).toBe(false);
        });
      });
    });
  });

  describe('Edit iteration', () => {
    const propsWithIteration = {
      groupPath,
      isEditing: true,
      iteration,
    };

    it('shows update text title', () => {
      createComponent({
        props: propsWithIteration,
      });

      expect(findPageTitle().text()).toBe('Edit iteration');
    });

    it('parses dates without adding timezone offsets', () => {
      createComponent({
        props: propsWithIteration,
      });

      expect(findStartDate().props('value').getTimezoneOffset()).toBe(0);
      expect(findDueDate().props('value').getTimezoneOffset()).toBe(0);
    });

    it('prefills form fields', () => {
      createComponent({
        props: propsWithIteration,
      });

      expect(findTitle().attributes('value')).toBe(iteration.title);
      expect(findDescription().element.value).toBe(iteration.description);

      expect(toDateString(findStartDate().attributes('value'))).toEqual(iteration.startDate);
      expect(toDateString(findDueDate().attributes('value'))).toEqual(iteration.dueDate);
    });

    it('shows update text on submit button', () => {
      createComponent({
        props: propsWithIteration,
      });

      expect(findSaveButton().text()).toBe('Save changes');
    });

    it('triggers mutation with form data', () => {
      createComponent({
        props: propsWithIteration,
      });

      inputFormData();
      clickSave();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateIteration,
        variables: {
          input: {
            groupPath,
            id: iteration.id,
            title,
            description,
            startDate,
            dueDate,
          },
        },
      });
    });

    it('emits updated event after successful mutation', async () => {
      createComponent({
        props: propsWithIteration,
        mutationResult: updateMutationSuccess,
      });

      clickSave();

      await nextTick();
      expect(findSaveButton().props('loading')).toBe(true);
      expect(wrapper.emitted('updated')).toHaveLength(1);
    });

    it('emits updated event after failed mutation', async () => {
      createComponent({
        props: propsWithIteration,
        mutationResult: updateMutationFailure,
      });

      clickSave();

      await nextTick();
      expect(wrapper.emitted('updated')).toBeUndefined();
    });

    it('validates required fields and sets isValid state to false', async () => {
      createComponent({
        props: propsWithIteration,
      });

      // remove input from edit page
      findTitle().vm.$emit('input', '');
      findStartDate().vm.$emit('input', null);
      findTitle().trigger('change');
      findStartDate().trigger('change');

      clickSave();

      await nextTick();

      expect(findSaveButton().props('loading')).toBe(false);
      expect(wrapper.vm.isValid).toBe(false);
      expect(wrapper.vm.titleState).toBe(false);
      expect(wrapper.vm.startDateState).toBe(false);
      expect(visitUrl).not.toHaveBeenCalled();
    });

    it('emits cancel when cancel clicked', async () => {
      createComponent({
        props: propsWithIteration,
        mutationResult: updateMutationSuccess,
      });

      clickCancel();

      await nextTick();
      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });
});
