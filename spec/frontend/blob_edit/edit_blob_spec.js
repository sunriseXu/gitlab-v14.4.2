import { Emitter } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import EditBlob from '~/blob_edit/edit_blob';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { FileTemplateExtension } from '~/editor/extensions/source_editor_file_template_ext';
import { EditorMarkdownExtension } from '~/editor/extensions/source_editor_markdown_ext';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import SourceEditor from '~/editor/source_editor';

jest.mock('~/editor/source_editor');
jest.mock('~/editor/extensions/source_editor_extension_base');
jest.mock('~/editor/extensions/source_editor_file_template_ext');
jest.mock('~/editor/extensions/source_editor_markdown_ext');
jest.mock('~/editor/extensions/source_editor_markdown_livepreview_ext');
jest.mock('~/editor/extensions/source_editor_toolbar_ext');

const PREVIEW_MARKDOWN_PATH = '/foo/bar/preview_markdown';
const defaultExtensions = [
  { definition: SourceEditorExtension },
  { definition: FileTemplateExtension },
  { definition: ToolbarExtension },
];
const markdownExtensions = [
  { definition: EditorMarkdownExtension },
  {
    definition: EditorMarkdownPreviewExtension,
    setupOptions: { previewMarkdownPath: PREVIEW_MARKDOWN_PATH },
  },
];

describe('Blob Editing', () => {
  let blobInstance;
  const useMock = jest.fn(() => markdownExtensions);
  const unuseMock = jest.fn();
  const emitter = new Emitter();
  const mockInstance = {
    use: useMock,
    unuse: unuseMock,
    setValue: jest.fn(),
    getValue: jest.fn().mockReturnValue('test value'),
    focus: jest.fn(),
    onDidChangeModelLanguage: emitter.event,
  };
  beforeEach(() => {
    setHTMLFixture(`
      <form class="js-edit-blob-form">
        <div id="file_path"></div>
        <div id="editor"></div>
        <textarea id="file-content"></textarea>
      </form>
    `);
    jest.spyOn(SourceEditor.prototype, 'createInstance').mockReturnValue(mockInstance);
  });
  afterEach(() => {
    jest.clearAllMocks();
    unuseMock.mockClear();
    useMock.mockClear();
    resetHTMLFixture();
  });

  const editorInst = (isMarkdown) => {
    blobInstance = new EditBlob({
      isMarkdown,
      previewMarkdownPath: PREVIEW_MARKDOWN_PATH,
    });
    return blobInstance;
  };

  const initEditor = async (isMarkdown = false) => {
    editorInst(isMarkdown);
    await waitForPromises();
  };

  it('loads SourceEditorExtension and FileTemplateExtension by default', async () => {
    await initEditor();
    expect(useMock).toHaveBeenCalledWith(defaultExtensions);
  });

  describe('Markdown', () => {
    it('does not load MarkdownExtensions by default', async () => {
      await initEditor();
      expect(EditorMarkdownExtension).not.toHaveBeenCalled();
      expect(EditorMarkdownPreviewExtension).not.toHaveBeenCalled();
    });

    it('loads MarkdownExtension only for the markdown files', async () => {
      await initEditor(true);
      expect(useMock).toHaveBeenCalledTimes(2);
      expect(useMock.mock.calls[1]).toEqual([markdownExtensions]);
    });

    it('correctly handles switching from markdown and un-uses markdown extensions', async () => {
      await initEditor(true);
      expect(unuseMock).not.toHaveBeenCalled();
      await emitter.fire({ newLanguage: 'plaintext', oldLanguage: 'markdown' });
      expect(unuseMock).toHaveBeenCalledWith(markdownExtensions);
    });

    it('correctly handles switching from non-markdown to markdown extensions', async () => {
      const mdSpy = jest.fn();
      await initEditor();
      blobInstance.fetchMarkdownExtension = mdSpy;
      expect(mdSpy).not.toHaveBeenCalled();
      await emitter.fire({ newLanguage: 'markdown', oldLanguage: 'plaintext' });
      expect(mdSpy).toHaveBeenCalled();
    });
  });

  it('adds trailing newline to the blob content on submit', async () => {
    const form = document.querySelector('.js-edit-blob-form');
    const fileContentEl = document.getElementById('file-content');

    await initEditor();

    form.dispatchEvent(new Event('submit'));

    expect(fileContentEl.value).toBe('test value\n');
  });
});
