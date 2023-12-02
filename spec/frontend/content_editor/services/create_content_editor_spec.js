import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';
import createGlApiMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import createRemarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import { createTestContentEditorExtension } from '../test_utils';

jest.mock('~/emoji');
jest.mock('~/content_editor/services/remark_markdown_deserializer');
jest.mock('~/content_editor/services/gl_api_markdown_deserializer');

describe('content_editor/services/create_content_editor', () => {
  let renderMarkdown;
  let editor;
  const uploadsPath = '/uploads';

  beforeEach(() => {
    renderMarkdown = jest.fn();
    window.gon = {
      features: {
        preserveUnchangedMarkdown: false,
      },
    };
    editor = createContentEditor({ renderMarkdown, uploadsPath });
  });

  describe('when preserveUnchangedMarkdown feature is on', () => {
    beforeEach(() => {
      window.gon.features.preserveUnchangedMarkdown = true;
    });

    it('provides a remark markdown deserializer to the content editor class', () => {
      createContentEditor({ renderMarkdown, uploadsPath });
      expect(createRemarkMarkdownDeserializer).toHaveBeenCalled();
    });
  });

  describe('when preserveUnchangedMarkdown feature is off', () => {
    beforeEach(() => {
      window.gon.features.preserveUnchangedMarkdown = false;
    });

    it('provides a gl api markdown deserializer to the content editor class', () => {
      createContentEditor({ renderMarkdown, uploadsPath });
      expect(createGlApiMarkdownDeserializer).toHaveBeenCalledWith({ render: renderMarkdown });
    });
  });

  it('sets gl-outline-0! class selector to the tiptapEditor instance', () => {
    expect(editor.tiptapEditor.options.editorProps).toMatchObject({
      attributes: {
        class: 'gl-outline-0!',
      },
    });
  });

  it('allows providing external content editor extensions', async () => {
    const labelReference = 'this is a ~group::editor';
    const { tiptapExtension, serializer } = createTestContentEditorExtension();

    editor = createContentEditor({
      renderMarkdown,
      extensions: [tiptapExtension],
      serializerConfig: { nodes: { [tiptapExtension.name]: serializer } },
    });

    editor.tiptapEditor.commands.setContent(
      '<p>this is a <span data-reference="label" data-label-name="group::editor">group::editor</span></p>',
    );

    expect(editor.getSerializedContent()).toBe(labelReference);
  });

  it('throws an error when a renderMarkdown fn is not provided', () => {
    expect(() => createContentEditor()).toThrow(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  });

  it('provides uploadsPath and renderMarkdown function to Attachment extension', () => {
    expect(
      editor.tiptapEditor.extensionManager.extensions.find((e) => e.name === 'attachment').options,
    ).toMatchObject({
      uploadsPath,
      renderMarkdown,
    });
  });
});
