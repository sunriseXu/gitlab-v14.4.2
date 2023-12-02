import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { objectToQuery, redirectTo } from '~/lib/utils/url_utility';
import { resolvers } from '~/pipeline_editor/graphql/resolvers';
import PipelineEditorTabs from '~/pipeline_editor/components/pipeline_editor_tabs.vue';
import PipelineEditorEmptyState from '~/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';
import PipelineEditorMessages from '~/pipeline_editor/components/ui/pipeline_editor_messages.vue';
import PipelineEditorHeader from '~/pipeline_editor/components/header/pipeline_editor_header.vue';
import ValidationSegment, {
  i18n as validationSegmenti18n,
} from '~/pipeline_editor/components/header/validation_segment.vue';
import {
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  COMMIT_FAILURE,
  EDITOR_APP_STATUS_LOADING,
} from '~/pipeline_editor/constants';
import getBlobContent from '~/pipeline_editor/graphql/queries/blob_content.query.graphql';
import getCiConfigData from '~/pipeline_editor/graphql/queries/ci_config.query.graphql';
import getTemplate from '~/pipeline_editor/graphql/queries/get_starter_template.query.graphql';
import getLatestCommitShaQuery from '~/pipeline_editor/graphql/queries/latest_commit_sha.query.graphql';
import getPipelineQuery from '~/pipeline_editor/graphql/queries/pipeline.query.graphql';
import getCurrentBranch from '~/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import getAppStatus from '~/pipeline_editor/graphql/queries/client/app_status.query.graphql';

import PipelineEditorApp from '~/pipeline_editor/pipeline_editor_app.vue';
import PipelineEditorHome from '~/pipeline_editor/pipeline_editor_home.vue';

import {
  mockCiConfigPath,
  mockCiConfigQueryResponse,
  mockBlobContentQueryResponse,
  mockBlobContentQueryResponseNoCiFile,
  mockCiYml,
  mockCiTemplateQueryResponse,
  mockCommitSha,
  mockCommitShaResults,
  mockDefaultBranch,
  mockEmptyCommitShaResults,
  mockNewCommitShaResults,
  mockNewMergeRequestPath,
  mockProjectFullPath,
} from './mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(VueApollo);

const mockProvide = {
  ciConfigPath: mockCiConfigPath,
  defaultBranch: mockDefaultBranch,
  newMergeRequestPath: mockNewMergeRequestPath,
  projectFullPath: mockProjectFullPath,
};

describe('Pipeline editor app component', () => {
  let wrapper;

  let mockApollo;
  let mockBlobContentData;
  let mockCiConfigData;
  let mockGetTemplate;
  let mockLatestCommitShaQuery;
  let mockPipelineQuery;

  const createComponent = ({
    blobLoading = false,
    options = {},
    provide = {},
    stubs = {},
  } = {}) => {
    wrapper = shallowMount(PipelineEditorApp, {
      provide: { ...mockProvide, ...provide },
      stubs,
      mocks: {
        $apollo: {
          queries: {
            initialCiFileContent: {
              loading: blobLoading,
            },
          },
        },
      },
      ...options,
    });
  };

  const createComponentWithApollo = async ({
    provide = {},
    stubs = {},
    withUndefinedBranch = false,
  } = {}) => {
    const handlers = [
      [getBlobContent, mockBlobContentData],
      [getCiConfigData, mockCiConfigData],
      [getTemplate, mockGetTemplate],
      [getLatestCommitShaQuery, mockLatestCommitShaQuery],
      [getPipelineQuery, mockPipelineQuery],
    ];

    mockApollo = createMockApollo(handlers, resolvers);

    if (!withUndefinedBranch) {
      mockApollo.clients.defaultClient.cache.writeQuery({
        query: getCurrentBranch,
        data: {
          workBranches: {
            __typename: 'BranchList',
            current: {
              __typename: 'WorkBranch',
              name: mockDefaultBranch,
            },
          },
        },
      });
    }

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getAppStatus,
      data: {
        app: {
          __typename: 'AppData',
          status: EDITOR_APP_STATUS_LOADING,
        },
      },
    });

    const options = {
      localVue,
      mocks: {},
      apolloProvider: mockApollo,
    };

    createComponent({ provide, stubs, options });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEditorHome = () => wrapper.findComponent(PipelineEditorHome);
  const findEmptyState = () => wrapper.findComponent(PipelineEditorEmptyState);
  const findEmptyStateButton = () => findEmptyState().findComponent(GlButton);
  const findValidationSegment = () => wrapper.findComponent(ValidationSegment);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
    mockCiConfigData = jest.fn();
    mockGetTemplate = jest.fn();
    mockLatestCommitShaQuery = jest.fn();
    mockPipelineQuery = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('displays a loading icon if the blob query is loading', () => {
      createComponent({ blobLoading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEditorHome().exists()).toBe(false);
    });
  });

  describe('skipping queries', () => {
    describe('when branchName is undefined', () => {
      beforeEach(async () => {
        await createComponentWithApollo({ withUndefinedBranch: true });
      });

      it('does not calls getBlobContent', () => {
        expect(mockBlobContentData).not.toHaveBeenCalled();
      });
    });

    describe('when branchName is defined', () => {
      beforeEach(async () => {
        await createComponentWithApollo();
      });

      it('calls getBlobContent', () => {
        expect(mockBlobContentData).toHaveBeenCalled();
      });
    });

    describe('when commit sha is undefined', () => {
      beforeEach(async () => {
        mockLatestCommitShaQuery.mockResolvedValue(undefined);
        await createComponentWithApollo();
      });

      it('calls getBlobContent', () => {
        expect(mockBlobContentData).toHaveBeenCalled();
      });

      it('does not call ciConfigData', () => {
        expect(mockCiConfigData).not.toHaveBeenCalled();
      });
    });

    describe('when commit sha is defined', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
        mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
        await createComponentWithApollo();
      });

      it('calls ciConfigData', () => {
        expect(mockCiConfigData).toHaveBeenCalled();
      });
    });
  });

  describe('when queries are called', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
    });

    describe('when file exists', () => {
      beforeEach(async () => {
        await createComponentWithApollo();

        jest
          .spyOn(wrapper.vm.$apollo.queries.commitSha, 'startPolling')
          .mockImplementation(jest.fn());
      });

      it('shows pipeline editor home component', () => {
        expect(findEditorHome().exists()).toBe(true);
      });

      it('no error is shown when data is set', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('ci config query is called with correct variables', async () => {
        expect(mockCiConfigData).toHaveBeenCalledWith({
          content: mockCiYml,
          projectPath: mockProjectFullPath,
          sha: mockCommitSha,
        });
      });

      it('does not poll for the commit sha', () => {
        expect(wrapper.vm.$apollo.queries.commitSha.startPolling).toHaveBeenCalledTimes(0);
      });
    });

    describe('when no CI config file exists', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        await createComponentWithApollo({
          stubs: {
            PipelineEditorEmptyState,
          },
        });

        jest
          .spyOn(wrapper.vm.$apollo.queries.commitSha, 'startPolling')
          .mockImplementation(jest.fn());
      });

      it('shows an empty state and does not show editor home component', async () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findAlert().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(false);
      });

      it('does not poll for the commit sha', () => {
        expect(wrapper.vm.$apollo.queries.commitSha.startPolling).toHaveBeenCalledTimes(0);
      });

      describe('because of a fetching error', () => {
        it('shows a unkown error message', async () => {
          const loadUnknownFailureText = 'The CI configuration was not loaded, please try again.';

          mockBlobContentData.mockRejectedValueOnce();
          await createComponentWithApollo({
            stubs: {
              PipelineEditorMessages,
            },
          });

          expect(findEmptyState().exists()).toBe(false);

          expect(findAlert().text()).toBe(loadUnknownFailureText);
          expect(findEditorHome().exists()).toBe(true);
        });
      });
    });

    describe('with no CI config setup', () => {
      it('user can click on CTA button to get started', async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        mockLatestCommitShaQuery.mockResolvedValue(mockEmptyCommitShaResults);

        await createComponentWithApollo({
          stubs: {
            PipelineEditorHome,
            PipelineEditorEmptyState,
          },
        });

        expect(findEmptyState().exists()).toBe(true);
        expect(findEditorHome().exists()).toBe(false);

        await findEmptyStateButton().vm.$emit('click');

        expect(findEmptyState().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(true);
      });
    });

    describe('when the lint query returns a 500 error', () => {
      beforeEach(async () => {
        mockCiConfigData.mockRejectedValueOnce(new Error(500));
        await createComponentWithApollo({
          stubs: { PipelineEditorHome, PipelineEditorHeader, ValidationSegment },
        });
      });

      it('shows that the lint service is down', () => {
        expect(findValidationSegment().text()).toContain(
          validationSegmenti18n.unavailableValidation,
        );
      });

      it('does not report an error or scroll to the top', () => {
        expect(findAlert().exists()).toBe(false);
        expect(window.scrollTo).not.toHaveBeenCalled();
      });
    });

    describe('when the user commits', () => {
      const updateFailureMessage = 'The GitLab CI configuration could not be updated.';
      const updateSuccessMessage = 'Your changes have been successfully committed.';

      describe('and the commit mutation succeeds', () => {
        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('commit', { type: COMMIT_SUCCESS });
        });

        it('shows a confirmation message', () => {
          expect(findAlert().text()).toBe(updateSuccessMessage);
        });

        it('scrolls to the top of the page to bring attention to the confirmation message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });

        it('polls for commit sha while pipeline data is not yet available for current branch', async () => {
          jest
            .spyOn(wrapper.vm.$apollo.queries.commitSha, 'startPolling')
            .mockImplementation(jest.fn());

          // simulate a commit to the current branch
          findEditorHome().vm.$emit('updateCommitSha');
          await waitForPromises();

          expect(wrapper.vm.$apollo.queries.commitSha.startPolling).toHaveBeenCalledTimes(1);
        });

        it('stops polling for commit sha when pipeline data is available for newly committed branch', async () => {
          jest
            .spyOn(wrapper.vm.$apollo.queries.commitSha, 'stopPolling')
            .mockImplementation(jest.fn());

          mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
          await wrapper.vm.$apollo.queries.commitSha.refetch();

          expect(wrapper.vm.$apollo.queries.commitSha.stopPolling).toHaveBeenCalledTimes(1);
        });

        it('stops polling for commit sha when pipeline data is available for current branch', async () => {
          jest
            .spyOn(wrapper.vm.$apollo.queries.commitSha, 'stopPolling')
            .mockImplementation(jest.fn());

          mockLatestCommitShaQuery.mockResolvedValue(mockNewCommitShaResults);
          findEditorHome().vm.$emit('updateCommitSha');
          await waitForPromises();

          expect(wrapper.vm.$apollo.queries.commitSha.stopPolling).toHaveBeenCalledTimes(1);
        });
      });

      describe('when the commit succeeds with a redirect', () => {
        const newBranch = 'new-branch';

        beforeEach(async () => {
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('commit', {
            type: COMMIT_SUCCESS_WITH_REDIRECT,
            params: { sourceBranch: newBranch, targetBranch: mockDefaultBranch },
          });
        });

        it('redirects to the merge request page with source and target branches', () => {
          const branchesQuery = objectToQuery({
            'merge_request[source_branch]': newBranch,
            'merge_request[target_branch]': mockDefaultBranch,
          });

          expect(redirectTo).toHaveBeenCalledWith(`${mockNewMergeRequestPath}?${branchesQuery}`);
        });
      });

      describe('and the commit mutation fails', () => {
        const commitFailedReasons = ['Commit failed'];

        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('showError', {
            type: COMMIT_FAILURE,
            reasons: commitFailedReasons,
          });
        });

        it('shows an error message', () => {
          expect(findAlert().text()).toMatchInterpolatedText(
            `${updateFailureMessage} ${commitFailedReasons[0]}`,
          );
        });

        it('scrolls to the top of the page to bring attention to the error message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });
      });

      describe('when an unknown error occurs', () => {
        const unknownReasons = ['Commit failed'];

        beforeEach(async () => {
          window.scrollTo = jest.fn();
          await createComponentWithApollo({ stubs: { PipelineEditorMessages } });

          findEditorHome().vm.$emit('showError', {
            type: COMMIT_FAILURE,
            reasons: unknownReasons,
          });
        });

        it('shows an error message', () => {
          expect(findAlert().text()).toMatchInterpolatedText(
            `${updateFailureMessage} ${unknownReasons[0]}`,
          );
        });

        it('scrolls to the top of the page to bring attention to the error message', () => {
          expect(window.scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' });
        });
      });
    });
  });

  describe('when refetching content', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
    });

    it('refetches blob content', async () => {
      await createComponentWithApollo();
      jest
        .spyOn(wrapper.vm.$apollo.queries.initialCiFileContent, 'refetch')
        .mockImplementation(jest.fn());

      expect(wrapper.vm.$apollo.queries.initialCiFileContent.refetch).toHaveBeenCalledTimes(0);

      await wrapper.vm.refetchContent();

      expect(wrapper.vm.$apollo.queries.initialCiFileContent.refetch).toHaveBeenCalledTimes(1);
    });

    it('hides start screen when refetch fetches CI file', async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
      await createComponentWithApollo();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEditorHome().exists()).toBe(false);

      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await wrapper.vm.$apollo.queries.initialCiFileContent.refetch();

      expect(findEmptyState().exists()).toBe(false);
      expect(findEditorHome().exists()).toBe(true);
    });
  });

  describe('when a template parameter is present in the URL', () => {
    const originalLocation = window.location.href;

    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
      mockLatestCommitShaQuery.mockResolvedValue(mockCommitShaResults);
      mockGetTemplate.mockResolvedValue(mockCiTemplateQueryResponse);
      setWindowLocation('?template=Android');
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    it('renders the given template', async () => {
      await createComponentWithApollo({
        stubs: { PipelineEditorHome, PipelineEditorTabs },
      });

      expect(mockGetTemplate).toHaveBeenCalledWith({
        projectPath: mockProjectFullPath,
        templateName: 'Android',
      });

      expect(findEmptyState().exists()).toBe(false);
      expect(findEditorHome().exists()).toBe(true);
    });
  });

  describe('when add_new_config_file query param is present', () => {
    const originalLocation = window.location.href;

    beforeEach(() => {
      setWindowLocation('?add_new_config_file=true');

      mockCiConfigData.mockResolvedValue(mockCiConfigQueryResponse);
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    describe('when CI config file does not exist', () => {
      beforeEach(async () => {
        mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponseNoCiFile);
        mockLatestCommitShaQuery.mockResolvedValue(mockEmptyCommitShaResults);
        mockGetTemplate.mockResolvedValue(mockCiTemplateQueryResponse);

        await createComponentWithApollo();

        jest
          .spyOn(wrapper.vm.$apollo.queries.commitSha, 'startPolling')
          .mockImplementation(jest.fn());
      });

      it('skips empty state and shows editor home component', () => {
        expect(findEmptyState().exists()).toBe(false);
        expect(findEditorHome().exists()).toBe(true);
      });
    });
  });
});
