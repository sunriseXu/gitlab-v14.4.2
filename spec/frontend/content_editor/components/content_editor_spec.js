import { GlAlert } from '@gitlab/ui';
import { EditorContent, Editor } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import ContentEditorAlert from '~/content_editor/components/content_editor_alert.vue';
import ContentEditorProvider from '~/content_editor/components/content_editor_provider.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import FormattingBubbleMenu from '~/content_editor/components/bubble_menus/formatting_bubble_menu.vue';
import CodeBlockBubbleMenu from '~/content_editor/components/bubble_menus/code_block_bubble_menu.vue';
import LinkBubbleMenu from '~/content_editor/components/bubble_menus/link_bubble_menu.vue';
import MediaBubbleMenu from '~/content_editor/components/bubble_menus/media_bubble_menu.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import LoadingIndicator from '~/content_editor/components/loading_indicator.vue';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/emoji');

describe('ContentEditor', () => {
  let wrapper;
  let renderMarkdown;
  const uploadsPath = '/uploads';

  const findEditorElement = () => wrapper.findByTestId('content-editor');
  const findEditorContent = () => wrapper.findComponent(EditorContent);
  const findEditorStateObserver = () => wrapper.findComponent(EditorStateObserver);
  const findLoadingIndicator = () => wrapper.findComponent(LoadingIndicator);
  const findContentEditorAlert = () => wrapper.findComponent(ContentEditorAlert);
  const createWrapper = ({ markdown } = {}) => {
    wrapper = shallowMountExtended(ContentEditor, {
      propsData: {
        renderMarkdown,
        uploadsPath,
        markdown,
      },
      stubs: {
        EditorStateObserver,
        ContentEditorProvider,
        ContentEditorAlert,
      },
    });
  };

  beforeEach(() => {
    renderMarkdown = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('triggers initialized event', () => {
    createWrapper();

    expect(wrapper.emitted('initialized')).toHaveLength(1);
  });

  it('renders EditorContent component and provides tiptapEditor instance', async () => {
    const markdown = 'hello world';

    createWrapper({ markdown });

    renderMarkdown.mockResolvedValueOnce(markdown);

    await nextTick();

    const editorContent = findEditorContent();

    expect(editorContent.props().editor).toBeInstanceOf(Editor);
    expect(editorContent.classes()).toContain('md');
  });

  it('renders ContentEditorProvider component', async () => {
    await createWrapper();

    expect(wrapper.findComponent(ContentEditorProvider).exists()).toBe(true);
  });

  it('renders top toolbar component', async () => {
    await createWrapper();

    expect(wrapper.findComponent(TopToolbar).exists()).toBe(true);
  });

  describe('when setting initial content', () => {
    it('displays loading indicator', async () => {
      createWrapper();

      await nextTick();

      expect(findLoadingIndicator().exists()).toBe(true);
    });

    it('emits loading event', async () => {
      createWrapper();

      await nextTick();

      expect(wrapper.emitted('loading')).toHaveLength(1);
    });

    describe('succeeds', () => {
      beforeEach(async () => {
        renderMarkdown.mockResolvedValueOnce('hello world');

        createWrapper({ markddown: 'hello world' });
        await nextTick();
      });

      it('hides loading indicator', async () => {
        await nextTick();
        expect(findLoadingIndicator().exists()).toBe(false);
      });

      it('emits loadingSuccess event', () => {
        expect(wrapper.emitted('loadingSuccess')).toHaveLength(1);
      });
    });

    describe('fails', () => {
      beforeEach(async () => {
        renderMarkdown.mockRejectedValueOnce(new Error());

        createWrapper({ markddown: 'hello world' });
        await nextTick();
      });

      it('sets the content editor as read only when loading content fails', async () => {
        await nextTick();

        expect(findEditorContent().props().editor.isEditable).toBe(false);
      });

      it('hides loading indicator', async () => {
        await nextTick();

        expect(findLoadingIndicator().exists()).toBe(false);
      });

      it('emits loadingError event', () => {
        expect(wrapper.emitted('loadingError')).toHaveLength(1);
      });

      it('displays error alert indicating that the content editor failed to load', () => {
        expect(findContentEditorAlert().text()).toContain(
          'An error occurred while trying to render the content editor. Please try again.',
        );
      });

      describe('when clicking the retry button in the loading error alert and loading succeeds', () => {
        beforeEach(async () => {
          renderMarkdown.mockResolvedValueOnce('hello markdown');
          await wrapper.findComponent(GlAlert).vm.$emit('primaryAction');
        });

        it('hides the loading error alert', () => {
          expect(findContentEditorAlert().text()).toBe('');
        });

        it('sets the content editor as writable', async () => {
          await nextTick();

          expect(findEditorContent().props().editor.isEditable).toBe(true);
        });
      });
    });
  });

  describe('when focused event is emitted', () => {
    beforeEach(async () => {
      createWrapper();

      findEditorStateObserver().vm.$emit('focus');

      await nextTick();
    });

    it('adds is-focused class when focus event is emitted', () => {
      expect(findEditorElement().classes()).toContain('is-focused');
    });

    it('removes is-focused class when blur event is emitted', async () => {
      findEditorStateObserver().vm.$emit('blur');

      await nextTick();

      expect(findEditorElement().classes()).not.toContain('is-focused');
    });
  });

  describe('when editorStateObserver emits docUpdate event', () => {
    it('emits change event with the latest markdown', async () => {
      const markdown = 'Loaded content';

      renderMarkdown.mockResolvedValueOnce(markdown);

      createWrapper({ markdown: 'initial content' });

      await nextTick();
      await waitForPromises();

      findEditorStateObserver().vm.$emit('docUpdate');

      expect(wrapper.emitted('change')).toEqual([
        [
          {
            markdown,
            changed: false,
            empty: false,
          },
        ],
      ]);
    });
  });

  it.each`
    name            | component
    ${'formatting'} | ${FormattingBubbleMenu}
    ${'link'}       | ${LinkBubbleMenu}
    ${'media'}      | ${MediaBubbleMenu}
    ${'codeBlock'}  | ${CodeBlockBubbleMenu}
  `('renders formatting bubble menu', ({ component }) => {
    createWrapper();

    expect(wrapper.findComponent(component).exists()).toBe(true);
  });
});
