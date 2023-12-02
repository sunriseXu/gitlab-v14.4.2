import { GlLink, GlForm } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import MediaBubbleMenu from '~/content_editor/components/bubble_menus/media_bubble_menu.vue';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import Image from '~/content_editor/extensions/image';
import Audio from '~/content_editor/extensions/audio';
import Video from '~/content_editor/extensions/video';
import { createTestEditor, emitEditorEvent, mockChainedCommands } from '../../test_utils';
import {
  PROJECT_WIKI_ATTACHMENT_IMAGE_HTML,
  PROJECT_WIKI_ATTACHMENT_AUDIO_HTML,
  PROJECT_WIKI_ATTACHMENT_VIDEO_HTML,
} from '../../test_constants';

const TIPTAP_IMAGE_HTML = `<p>
  <img src="https://gitlab.com/favicon.png" alt="gitlab favicon" title="gitlab favicon">
</p>`;

const TIPTAP_AUDIO_HTML = `<p>
  <span class="media-container audio-container"><audio src="https://gitlab.com/favicon.png" controls="true" data-setup="{}" data-title="gitlab favicon"></audio><a href="https://gitlab.com/favicon.png">gitlab favicon</a></span>
</p>`;

const TIPTAP_VIDEO_HTML = `<p>
  <span class="media-container video-container"><video src="https://gitlab.com/favicon.png" controls="true" data-setup="{}" data-title="gitlab favicon"></video><a href="https://gitlab.com/favicon.png">gitlab favicon</a></span>
</p>`;

const createFakeEvent = () => ({ preventDefault: jest.fn(), stopPropagation: jest.fn() });

describe.each`
  mediaType  | mediaHTML                             | filePath           | mediaOutputHTML
  ${'image'} | ${PROJECT_WIKI_ATTACHMENT_IMAGE_HTML} | ${'test-file.png'} | ${TIPTAP_IMAGE_HTML}
  ${'audio'} | ${PROJECT_WIKI_ATTACHMENT_AUDIO_HTML} | ${'test-file.mp3'} | ${TIPTAP_AUDIO_HTML}
  ${'video'} | ${PROJECT_WIKI_ATTACHMENT_VIDEO_HTML} | ${'test-file.mp4'} | ${TIPTAP_VIDEO_HTML}
`(
  'content_editor/components/bubble_menus/media_bubble_menu ($mediaType)',
  ({ mediaType, mediaHTML, filePath, mediaOutputHTML }) => {
    let wrapper;
    let tiptapEditor;
    let contentEditor;
    let bubbleMenu;
    let eventHub;

    const buildEditor = () => {
      tiptapEditor = createTestEditor({ extensions: [Image, Audio, Video] });
      contentEditor = { resolveUrl: jest.fn() };
      eventHub = eventHubFactory();
    };

    const buildWrapper = () => {
      wrapper = mountExtended(MediaBubbleMenu, {
        provide: {
          tiptapEditor,
          contentEditor,
          eventHub,
        },
        stubs: {
          BubbleMenu: stubComponent(BubbleMenu),
        },
      });
    };

    const selectFile = async (file) => {
      const input = wrapper.findComponent({ ref: 'fileSelector' });

      // override the property definition because `input.files` isn't directly modifyable
      Object.defineProperty(input.element, 'files', { value: [file], writable: true });
      await input.trigger('change');
    };

    const expectLinkButtonsToExist = (exist = true) => {
      expect(wrapper.findComponent(GlLink).exists()).toBe(exist);
      expect(wrapper.findByTestId('copy-media-src').exists()).toBe(exist);
      expect(wrapper.findByTestId('edit-media').exists()).toBe(exist);
      expect(wrapper.findByTestId('delete-media').exists()).toBe(exist);
    };

    beforeEach(async () => {
      buildEditor();
      buildWrapper();

      tiptapEditor
        .chain()
        .insertContent(mediaHTML)
        .setNodeSelection(4) // select the media
        .run();

      contentEditor.resolveUrl.mockResolvedValue(`/group1/project1/-/wikis/${filePath}`);

      await emitEditorEvent({ event: 'transaction', tiptapEditor });

      bubbleMenu = wrapper.findComponent(BubbleMenu);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders bubble menu component', async () => {
      expect(bubbleMenu.classes()).toEqual(['gl-shadow', 'gl-rounded-base', 'gl-bg-white']);
    });

    it('shows a clickable link to the image', async () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.attributes()).toEqual(
        expect.objectContaining({
          href: `/group1/project1/-/wikis/${filePath}`,
          'aria-label': filePath,
          title: filePath,
          target: '_blank',
        }),
      );
      expect(link.text()).toBe(filePath);
    });

    describe('copy button', () => {
      it(`copies the canonical link to the ${mediaType} to clipboard`, async () => {
        jest.spyOn(navigator.clipboard, 'writeText');

        await wrapper.findByTestId('copy-media-src').vm.$emit('click');

        expect(navigator.clipboard.writeText).toHaveBeenCalledWith(filePath);
      });
    });

    describe(`remove ${mediaType} button`, () => {
      it(`removes the ${mediaType}`, async () => {
        await wrapper.findByTestId('delete-media').vm.$emit('click');

        expect(tiptapEditor.getHTML()).toBe('<p>\n  \n</p>');
      });
    });

    describe(`replace ${mediaType} button`, () => {
      it('uploads and replaces the selected image when file input changes', async () => {
        const commands = mockChainedCommands(tiptapEditor, [
          'focus',
          'deleteSelection',
          'uploadAttachment',
          'run',
        ]);
        const file = new File(['foo'], 'foo.png', { type: 'image/png' });

        await wrapper.findByTestId('replace-media').vm.$emit('click');
        await selectFile(file);

        expect(commands.focus).toHaveBeenCalled();
        expect(commands.deleteSelection).toHaveBeenCalled();
        expect(commands.uploadAttachment).toHaveBeenCalledWith({ file });
        expect(commands.run).toHaveBeenCalled();
      });
    });

    describe('edit button', () => {
      let mediaSrcInput;
      let mediaTitleInput;
      let mediaAltInput;

      beforeEach(async () => {
        await wrapper.findByTestId('edit-media').vm.$emit('click');

        mediaSrcInput = wrapper.findByTestId('media-src');
        mediaTitleInput = wrapper.findByTestId('media-title');
        mediaAltInput = wrapper.findByTestId('media-alt');
      });

      it('hides the link and copy/edit/remove link buttons', async () => {
        expectLinkButtonsToExist(false);
      });

      it(`shows a form to edit the ${mediaType} src/title/alt`, () => {
        expect(wrapper.findComponent(GlForm).exists()).toBe(true);

        expect(mediaSrcInput.element.value).toBe(filePath);
        expect(mediaTitleInput.element.value).toBe('');
        expect(mediaAltInput.element.value).toBe('test-file');
      });

      describe('after making changes in the form and clicking apply', () => {
        beforeEach(async () => {
          mediaSrcInput.setValue('https://gitlab.com/favicon.png');
          mediaAltInput.setValue('gitlab favicon');
          mediaTitleInput.setValue('gitlab favicon');

          contentEditor.resolveUrl.mockResolvedValue('https://gitlab.com/favicon.png');

          await wrapper.findComponent(GlForm).vm.$emit('submit', createFakeEvent());
        });

        it(`updates prosemirror doc with new src to the ${mediaType}`, async () => {
          expect(tiptapEditor.getHTML()).toBe(mediaOutputHTML);
        });

        it(`updates the link to the ${mediaType} in the bubble menu`, () => {
          const link = wrapper.findComponent(GlLink);
          expect(link.attributes()).toEqual(
            expect.objectContaining({
              href: 'https://gitlab.com/favicon.png',
              'aria-label': 'https://gitlab.com/favicon.png',
              title: 'https://gitlab.com/favicon.png',
              target: '_blank',
            }),
          );
          expect(link.text()).toBe('https://gitlab.com/favicon.png');
        });
      });

      describe('after making changes in the form and clicking cancel', () => {
        beforeEach(async () => {
          mediaSrcInput.setValue('https://gitlab.com/favicon.png');
          mediaAltInput.setValue('gitlab favicon');
          mediaTitleInput.setValue('gitlab favicon');

          await wrapper.findByTestId('cancel-editing-media').vm.$emit('click');
        });

        it('hides the form and shows the copy/edit/remove link buttons', () => {
          expectLinkButtonsToExist();
        });

        it(`resets the form with old values of the ${mediaType} from prosemirror`, async () => {
          // click edit once again to show the form back
          await wrapper.findByTestId('edit-media').vm.$emit('click');

          mediaSrcInput = wrapper.findByTestId('media-src');
          mediaTitleInput = wrapper.findByTestId('media-title');
          mediaAltInput = wrapper.findByTestId('media-alt');

          expect(mediaSrcInput.element.value).toBe(filePath);
          expect(mediaAltInput.element.value).toBe('test-file');
          expect(mediaTitleInput.element.value).toBe('');
        });
      });
    });
  },
);
