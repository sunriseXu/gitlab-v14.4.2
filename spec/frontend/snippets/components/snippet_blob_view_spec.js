import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import {
  Blob as BlobMock,
  SimpleViewerMock,
  RichViewerMock,
  RichBlobContentMock,
  SimpleBlobContentMock,
} from 'jest/blob/components/mock_data';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import {
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
  BLOB_RENDER_ERRORS,
} from '~/blob/components/constants';
import SnippetBlobView from '~/snippets/components/snippet_blob_view.vue';
import { VISIBILITY_LEVEL_PUBLIC_STRING } from '~/visibility_level/constants';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';

describe('Blob Embeddable', () => {
  let wrapper;
  const snippet = {
    id: 'gid://foo.bar/snippet',
    webUrl: 'https://foo.bar',
    visibilityLevel: VISIBILITY_LEVEL_PUBLIC_STRING,
  };
  const dataMock = {
    activeViewerType: SimpleViewerMock.type,
  };

  function createComponent({
    snippetProps = {},
    data = dataMock,
    blob = BlobMock,
    contentLoading = false,
  } = {}) {
    const $apollo = {
      queries: {
        blobContent: {
          loading: contentLoading,
          refetch: jest.fn(),
          skip: true,
        },
      },
    };

    wrapper = mount(SnippetBlobView, {
      propsData: {
        snippet: {
          ...snippet,
          ...snippetProps,
        },
        blob,
      },
      data() {
        return {
          ...data,
        };
      },
      mocks: { $apollo },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('renders correct components', () => {
      createComponent();
      expect(wrapper.find(BlobHeader).exists()).toBe(true);
      expect(wrapper.find(BlobContent).exists()).toBe(true);
    });

    it('sets simple viewer correctly', () => {
      createComponent();
      expect(wrapper.find(SimpleViewer).exists()).toBe(true);
    });

    it('sets rich viewer correctly', () => {
      const data = { ...dataMock, activeViewerType: RichViewerMock.type };
      createComponent({
        data,
      });
      expect(wrapper.find(RichViewer).exists()).toBe(true);
    });

    it('correctly switches viewer type', async () => {
      createComponent();
      expect(wrapper.find(SimpleViewer).exists()).toBe(true);

      wrapper.vm.switchViewer(RichViewerMock.type);

      await nextTick();
      expect(wrapper.find(RichViewer).exists()).toBe(true);
      await wrapper.vm.switchViewer(SimpleViewerMock.type);

      expect(wrapper.find(SimpleViewer).exists()).toBe(true);
    });

    it('passes information about render error down to blob header', () => {
      createComponent({
        blob: {
          ...BlobMock,
          simpleViewer: {
            ...SimpleViewerMock,
            renderError: BLOB_RENDER_ERRORS.REASONS.COLLAPSED.id,
          },
        },
      });

      expect(wrapper.find(BlobHeader).props('hasRenderError')).toBe(true);
    });

    describe('bob content in multi-file scenario', () => {
      const SimpleBlobContentMock2 = {
        ...SimpleBlobContentMock,
        plainData: 'Another Plain Foo',
      };
      const RichBlobContentMock2 = {
        ...SimpleBlobContentMock,
        richData: 'Another Rich Foo',
      };

      it.each`
        snippetBlobs                                       | description                                  | currentBlob              | expectedContent
        ${[SimpleBlobContentMock]}                         | ${'one existing textual blob'}               | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData}
        ${[RichBlobContentMock]}                           | ${'one existing rich blob'}                  | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}
        ${[SimpleBlobContentMock, RichBlobContentMock]}    | ${'mixed blobs with current textual blob'}   | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData}
        ${[SimpleBlobContentMock, RichBlobContentMock]}    | ${'mixed blobs with current rich blob'}      | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}
        ${[SimpleBlobContentMock, SimpleBlobContentMock2]} | ${'textual blobs with current textual blob'} | ${SimpleBlobContentMock} | ${SimpleBlobContentMock.plainData}
        ${[RichBlobContentMock, RichBlobContentMock2]}     | ${'rich blobs with current rich blob'}       | ${RichBlobContentMock}   | ${RichBlobContentMock.richData}
      `(
        'renders correct content for $description',
        async ({ snippetBlobs, currentBlob, expectedContent }) => {
          const apolloData = {
            snippets: {
              nodes: [
                {
                  blobs: {
                    nodes: snippetBlobs,
                  },
                },
              ],
            },
          };
          createComponent({
            blob: {
              ...BlobMock,
              path: currentBlob.path,
            },
          });

          // mimic apollo's update
          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          wrapper.setData({
            blobContent: wrapper.vm.onContentUpdate(apolloData),
          });

          await nextTick();

          const findContent = () => wrapper.find(BlobContent);

          expect(findContent().props('content')).toBe(expectedContent);
        },
      );
    });

    describe('URLS with hash', () => {
      beforeEach(() => {
        window.location.hash = '#LC2';
      });

      afterEach(() => {
        window.location.hash = '';
      });

      it('renders simple viewer by default if URL contains hash', () => {
        createComponent({
          data: {},
        });

        expect(wrapper.vm.activeViewerType).toBe(SimpleViewerMock.type);
        expect(wrapper.find(SimpleViewer).exists()).toBe(true);
      });

      describe('switchViewer()', () => {
        it('switches to the passed viewer', async () => {
          createComponent();

          wrapper.vm.switchViewer(RichViewerMock.type);

          await nextTick();
          expect(wrapper.vm.activeViewerType).toBe(RichViewerMock.type);
          expect(wrapper.find(RichViewer).exists()).toBe(true);

          await wrapper.vm.switchViewer(SimpleViewerMock.type);
          expect(wrapper.vm.activeViewerType).toBe(SimpleViewerMock.type);
          expect(wrapper.find(SimpleViewer).exists()).toBe(true);
        });
      });
    });
  });

  describe('functionality', () => {
    describe('render error', () => {
      const findContentEl = () => wrapper.find(BlobContent);

      it('correctly sets blob on the blob-content-error component', () => {
        createComponent();
        expect(findContentEl().props('blob')).toEqual(BlobMock);
      });

      it(`refetches blob content on ${BLOB_RENDER_EVENT_LOAD} event`, () => {
        createComponent();

        expect(wrapper.vm.$apollo.queries.blobContent.refetch).not.toHaveBeenCalled();
        findContentEl().vm.$emit(BLOB_RENDER_EVENT_LOAD);
        expect(wrapper.vm.$apollo.queries.blobContent.refetch).toHaveBeenCalledTimes(1);
      });

      it(`sets '${SimpleViewerMock.type}' as active on ${BLOB_RENDER_EVENT_SHOW_SOURCE} event`, () => {
        createComponent({
          data: {
            activeViewerType: RichViewerMock.type,
          },
        });

        findContentEl().vm.$emit(BLOB_RENDER_EVENT_SHOW_SOURCE);
        expect(wrapper.vm.activeViewerType).toEqual(SimpleViewerMock.type);
      });
    });
  });
});
