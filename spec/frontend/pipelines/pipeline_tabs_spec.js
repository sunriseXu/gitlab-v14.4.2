import { createAppOptions, createPipelineTabs } from '~/pipelines/pipeline_tabs';
import { updateHistory } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  removeParams: () => 'gitlab.com',
  updateHistory: jest.fn(),
  joinPaths: () => {},
  setUrlFragment: () => {},
}));

jest.mock('~/pipelines/utils', () => ({
  getPipelineDefaultTab: () => '',
}));

describe('~/pipelines/pipeline_tabs.js', () => {
  describe('createAppOptions', () => {
    const SELECTOR = 'SELECTOR';

    let el;

    const createElement = () => {
      el = document.createElement('div');
      el.id = SELECTOR;
      el.dataset.canGenerateCodequalityReports = 'true';
      el.dataset.codequalityReportDownloadPath = 'codequalityReportDownloadPath';
      el.dataset.downloadablePathForReportType = 'downloadablePathForReportType';
      el.dataset.exposeSecurityDashboard = 'true';
      el.dataset.exposeLicenseScanningData = 'true';
      el.dataset.failedJobsCount = 1;
      el.dataset.failedJobsSummary = '[]';
      el.dataset.graphqlResourceEtag = 'graphqlResourceEtag';
      el.dataset.pipelineIid = '123';
      el.dataset.pipelineProjectPath = 'pipelineProjectPath';

      document.body.appendChild(el);
    };

    afterEach(() => {
      el = null;
    });

    it("extracts the properties from the element's dataset", () => {
      createElement();
      const options = createAppOptions(`#${SELECTOR}`, null);

      expect(options).toMatchObject({
        el,
        provide: {
          canGenerateCodequalityReports: true,
          codequalityReportDownloadPath: 'codequalityReportDownloadPath',
          downloadablePathForReportType: 'downloadablePathForReportType',
          exposeSecurityDashboard: true,
          exposeLicenseScanningData: true,
          failedJobsCount: '1',
          failedJobsSummary: [],
          graphqlResourceEtag: 'graphqlResourceEtag',
          pipelineIid: '123',
          pipelineProjectPath: 'pipelineProjectPath',
        },
      });
    });

    it('returns `null` if el does not exist', () => {
      expect(createAppOptions('foo', null)).toBe(null);
    });
  });

  describe('createPipelineTabs', () => {
    const title = 'Pipeline Tabs';

    beforeAll(() => {
      document.title = title;
    });

    afterAll(() => {
      document.title = '';
    });

    it('calls `updateHistory` with correct params', () => {
      createPipelineTabs({});

      expect(updateHistory).toHaveBeenCalledWith({
        title,
        url: 'gitlab.com',
        replace: true,
      });
    });

    it("returns early if options aren't provided", () => {
      createPipelineTabs();

      expect(updateHistory).not.toHaveBeenCalled();
    });
  });
});
