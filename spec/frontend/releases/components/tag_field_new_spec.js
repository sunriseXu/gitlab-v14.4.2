import { GlDropdownItem } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import { __ } from '~/locale';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_PROJECT_ID = '1234';
const TEST_CREATE_FROM = 'test-create-from';
const NONEXISTENT_TAG_NAME = 'nonexistent-tag';

describe('releases/components/tag_field_new', () => {
  let store;
  let wrapper;
  let mock;
  let RefSelectorStub;

  const createComponent = (
    mountFn = shallowMount,
    { searchQuery } = { searchQuery: NONEXISTENT_TAG_NAME },
  ) => {
    // A mock version of the RefSelector component that just renders the
    // #footer slot, so that the content inside this slot can be tested.
    RefSelectorStub = Vue.component('RefSelectorStub', {
      data() {
        return {
          footerSlotProps: {
            isLoading: false,
            matches: {
              tags: {
                totalCount: 1,
                list: [{ name: TEST_TAG_NAME }],
              },
            },
            query: searchQuery,
          },
        };
      },
      template: '<div><slot name="footer" v-bind="footerSlotProps"></slot></div>',
    });

    wrapper = mountFn(TagFieldNew, {
      store,
      stubs: {
        RefSelector: RefSelectorStub,
      },
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          projectId: TEST_PROJECT_ID,
        }),
      },
    });

    store.state.editNew.createFrom = TEST_CREATE_FROM;

    store.state.editNew.release = {
      tagName: TEST_TAG_NAME,
      assets: {
        links: [],
      },
    };

    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findTagNameFormGroup = () => wrapper.find('[data-testid="tag-name-field"]');
  const findTagNameDropdown = () => findTagNameFormGroup().findComponent(RefSelectorStub);

  const findCreateFromFormGroup = () => wrapper.find('[data-testid="create-from-field"]');
  const findCreateFromDropdown = () => findCreateFromFormGroup().findComponent(RefSelectorStub);

  const findCreateNewTagOption = () => wrapper.findComponent(GlDropdownItem);

  describe('"Tag name" field', () => {
    describe('rendering and behavior', () => {
      beforeEach(() => createComponent());

      it('renders a label', () => {
        expect(findTagNameFormGroup().attributes().label).toBe(__('Tag name'));
        expect(findTagNameFormGroup().props().labelDescription).toBe(__('*Required'));
      });

      describe('when the user selects a new tag name', () => {
        beforeEach(async () => {
          findCreateNewTagOption().vm.$emit('click');
        });

        it("updates the store's release.tagName property", () => {
          expect(store.state.editNew.release.tagName).toBe(NONEXISTENT_TAG_NAME);
        });

        it('hides the "Create from" field', () => {
          expect(findCreateFromFormGroup().exists()).toBe(true);
        });
      });

      describe('when the user selects an existing tag name', () => {
        const updatedTagName = 'updated-tag-name';

        beforeEach(async () => {
          findTagNameDropdown().vm.$emit('input', updatedTagName);
        });

        it("updates the store's release.tagName property", () => {
          expect(store.state.editNew.release.tagName).toBe(updatedTagName);
        });

        it('hides the "Create from" field', () => {
          expect(findCreateFromFormGroup().exists()).toBe(false);
        });

        it('fetches the release notes for the tag', () => {
          const expectedUrl = `/api/v4/projects/1234/repository/tags/${updatedTagName}`;
          expect(mock.history.get).toContainEqual(expect.objectContaining({ url: expectedUrl }));
        });
      });
    });

    describe('"Create tag" option', () => {
      describe('when the search query exactly matches one of the search results', () => {
        beforeEach(async () => {
          createComponent(mount, { searchQuery: TEST_TAG_NAME });
        });

        it('does not show the "Create tag" option', () => {
          expect(findCreateNewTagOption().exists()).toBe(false);
        });
      });

      describe('when the search query does not exactly match one of the search results', () => {
        beforeEach(async () => {
          createComponent(mount, { searchQuery: NONEXISTENT_TAG_NAME });
        });

        it('shows the "Create tag" option', () => {
          expect(findCreateNewTagOption().exists()).toBe(true);
        });
      });
    });

    describe('validation', () => {
      beforeEach(() => {
        createComponent(mount);
      });

      /**
       * Utility function to test the visibility of the validation message
       * @param {'shown' | 'hidden'} state The expected state of the validation message.
       * Should be passed either 'shown' or 'hidden'
       */
      const expectValidationMessageToBe = async (state) => {
        await nextTick();

        expect(findTagNameFormGroup().element).toHaveClass(
          state === 'shown' ? 'is-invalid' : 'is-valid',
        );
        expect(findTagNameFormGroup().element).not.toHaveClass(
          state === 'shown' ? 'is-valid' : 'is-invalid',
        );
      };

      describe('when the user has not yet interacted with the component', () => {
        it('does not display a validation error', async () => {
          findTagNameDropdown().vm.$emit('input', '');

          await expectValidationMessageToBe('hidden');
        });
      });

      describe('when the user has interacted with the component and the value is not empty', () => {
        it('does not display validation error', async () => {
          findTagNameDropdown().vm.$emit('hide');

          await expectValidationMessageToBe('hidden');
        });

        it('displays a validation error if the tag has an associated release', async () => {
          findTagNameDropdown().vm.$emit('input', 'vTest');
          findTagNameDropdown().vm.$emit('hide');

          store.state.editNew.existingRelease = {};

          await expectValidationMessageToBe('shown');
          expect(findTagNameFormGroup().text()).toContain(
            __('Selected tag is already in use. Choose another option.'),
          );
        });
      });

      describe('when the user has interacted with the component and the value is empty', () => {
        it('displays a validation error', async () => {
          findTagNameDropdown().vm.$emit('input', '');
          findTagNameDropdown().vm.$emit('hide');

          await expectValidationMessageToBe('shown');
          expect(findTagNameFormGroup().text()).toContain(__('Tag name is required.'));
        });
      });
    });
  });

  describe('"Create from" field', () => {
    beforeEach(() => createComponent());

    it('renders a label', () => {
      expect(findCreateFromFormGroup().attributes().label).toBe('Create from');
    });

    describe('when the user selects a git ref', () => {
      it("updates the store's createFrom property", async () => {
        const updatedCreateFrom = 'update-create-from';
        findCreateFromDropdown().vm.$emit('input', updatedCreateFrom);

        expect(store.state.editNew.createFrom).toBe(updatedCreateFrom);
      });
    });
  });
});
