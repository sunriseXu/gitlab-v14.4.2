import MockAdapter from 'axios-mock-adapter';
import {
  axiosInstance,
  addSubscription,
  removeSubscription,
  fetchGroups,
  getCurrentUser,
  addJiraConnectSubscription,
  updateInstallation,
} from '~/jira_connect/subscriptions/api';
import { getJwt } from '~/jira_connect/subscriptions/utils';
import httpStatus from '~/lib/utils/http_status';

jest.mock('~/jira_connect/subscriptions/utils', () => ({
  getJwt: jest.fn().mockResolvedValue('jwt'),
}));

describe('JiraConnect API', () => {
  let axiosMock;
  let originalGon;
  let response;

  const mockAddPath = 'addPath';
  const mockRemovePath = 'removePath';
  const mockNamespace = 'namespace';
  const mockJwt = 'jwt';
  const mockAccessToken = 'accessToken';
  const mockResponse = { success: true };

  beforeEach(() => {
    axiosMock = new MockAdapter(axiosInstance);
    originalGon = window.gon;
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    axiosMock.restore();
    window.gon = originalGon;
    response = null;
  });

  describe('addSubscription', () => {
    const makeRequest = () => addSubscription(mockAddPath, mockNamespace);

    it('returns success response', async () => {
      jest.spyOn(axiosInstance, 'post');
      axiosMock
        .onPost(mockAddPath, {
          jwt: mockJwt,
          namespace_path: mockNamespace,
        })
        .replyOnce(httpStatus.OK, mockResponse);

      response = await makeRequest();

      expect(getJwt).toHaveBeenCalled();
      expect(axiosInstance.post).toHaveBeenCalledWith(mockAddPath, {
        jwt: mockJwt,
        namespace_path: mockNamespace,
      });
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('removeSubscription', () => {
    const makeRequest = () => removeSubscription(mockRemovePath);

    it('returns success response', async () => {
      jest.spyOn(axiosInstance, 'delete');
      axiosMock.onDelete(mockRemovePath).replyOnce(httpStatus.OK, mockResponse);

      response = await makeRequest();

      expect(getJwt).toHaveBeenCalled();
      expect(axiosInstance.delete).toHaveBeenCalledWith(mockRemovePath, {
        params: {
          jwt: mockJwt,
        },
      });
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('fetchGroups', () => {
    const mockGroupsPath = 'groupsPath';
    const mockPage = 1;
    const mockPerPage = 10;

    const makeRequest = () =>
      fetchGroups(mockGroupsPath, {
        page: mockPage,
        perPage: mockPerPage,
      });

    it('returns success response', async () => {
      jest.spyOn(axiosInstance, 'get');
      axiosMock
        .onGet(mockGroupsPath, {
          page: mockPage,
          per_page: mockPerPage,
        })
        .replyOnce(httpStatus.OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.get).toHaveBeenCalledWith(mockGroupsPath, {
        params: {
          page: mockPage,
          per_page: mockPerPage,
        },
      });
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('getCurrentUser', () => {
    const makeRequest = () => getCurrentUser();

    it('returns success response', async () => {
      const expectedUrl = '/api/v4/user';

      jest.spyOn(axiosInstance, 'get');

      axiosMock.onGet(expectedUrl).replyOnce(httpStatus.OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.get).toHaveBeenCalledWith(expectedUrl, {});
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('addJiraConnectSubscription', () => {
    const makeRequest = () =>
      addJiraConnectSubscription(mockNamespace, { jwt: mockJwt, accessToken: mockAccessToken });

    it('returns success response', async () => {
      const expectedUrl = '/api/v4/integrations/jira_connect/subscriptions';

      jest.spyOn(axiosInstance, 'post');

      axiosMock.onPost(expectedUrl).replyOnce(httpStatus.OK, mockResponse);

      response = await makeRequest();

      expect(axiosInstance.post).toHaveBeenCalledWith(
        expectedUrl,
        {
          jwt: mockJwt,
          namespace_path: mockNamespace,
        },
        { headers: { Authorization: `Bearer ${mockAccessToken}` } },
      );
      expect(response.data).toEqual(mockResponse);
    });
  });

  describe('updateInstallation', () => {
    const expectedUrl = '/-/jira_connect/installations';

    it.each`
      instanceUrl                       | expectedInstanceUrl
      ${'https://gitlab.com'}           | ${null}
      ${'https://gitlab.mycompany.com'} | ${'https://gitlab.mycompany.com'}
    `(
      'when instanceUrl is $instanceUrl, it passes `instance_url` as $expectedInstanceUrl',
      async ({ instanceUrl, expectedInstanceUrl }) => {
        const makeRequest = () => updateInstallation(instanceUrl);

        jest.spyOn(axiosInstance, 'put');
        axiosMock
          .onPut(expectedUrl, {
            jwt: mockJwt,
            installation: {
              instance_url: expectedInstanceUrl,
            },
          })
          .replyOnce(httpStatus.OK, mockResponse);

        response = await makeRequest();

        expect(getJwt).toHaveBeenCalled();
        expect(axiosInstance.put).toHaveBeenCalledWith(expectedUrl, {
          jwt: mockJwt,
          installation: {
            instance_url: expectedInstanceUrl,
          },
        });
        expect(response.data).toEqual(mockResponse);
      },
    );
  });
});
