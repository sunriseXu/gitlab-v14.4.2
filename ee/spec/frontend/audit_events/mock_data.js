import { uniqueId } from 'lodash';
import { slugify } from '~/lib/utils/text_utility';

const DEFAULT_EVENT = {
  action: 'Signed in with STANDARD authentication',
  date: '2020-03-18 12:04:23',
  ip_address: '127.0.0.1',
};

const populateEvent = (user, hasAuthorUrl = true, hasObjectUrl = true) => {
  const author = { name: user, url: null };
  const object = { name: user, url: null };
  const userSlug = slugify(user);

  if (hasAuthorUrl) {
    author.url = `/${userSlug}`;
  }

  if (hasObjectUrl) {
    object.url = `http://127.0.0.1:3000/${userSlug}`;
  }

  return {
    ...DEFAULT_EVENT,
    author,
    object,
    target: user,
  };
};

export default () => [
  populateEvent('User'),
  populateEvent('User 2', false),
  populateEvent('User 3', true, false),
  populateEvent('User 4', false, false),
];

export const mockExternalDestinationUrl = 'https://api.gitlab.com';
export const mockExternalDestinationHeader = () => ({
  id: uniqueId('gid://gitlab/AuditEvents::Streaming::Header/'),
  key: uniqueId('header-key-'),
  value: uniqueId('header-value-'),
});
export const mockExternalDestinations = [
  {
    id: 'test_id1',
    destinationUrl: mockExternalDestinationUrl,
    verificationToken: 'id5hzCbERzSkQ82tAs16tH5Y',
    headers: {
      nodes: [],
    },
  },
  {
    id: 'test_id2',
    destinationUrl: 'https://apiv2.gitlab.com',
    verificationToken: 'JsSQtg86au6buRtX9j98sYa8',
    headers: {
      nodes: [],
    },
  },
];

export const groupPath = 'test-group';

export const testGroupId = 'test-group-id';

export const destinationDataPopulator = (nodes) => ({
  data: {
    group: { id: testGroupId, externalAuditEventDestinations: { nodes } },
  },
});

export const destinationCreateMutationPopulator = (errors = []) => {
  const correctData = {
    errors,
    externalAuditEventDestination: {
      id: 'test-create-id',
      destinationUrl: mockExternalDestinationUrl,
      verificationToken: 'Cr28SHnrJtgpSXUEGfictGMS',
      group: {
        name: groupPath,
        id: testGroupId,
      },
    },
  };

  const errorData = {
    errors,
    externalAuditEventDestination: {
      id: null,
      destinationUrl: null,
      verificationToken: null,
      group: {
        name: null,
        id: testGroupId,
      },
    },
  };

  return {
    data: {
      externalAuditEventDestinationCreate: errors.length > 0 ? errorData : correctData,
    },
  };
};

export const destinationDeleteMutationPopulator = (errors = []) => ({
  data: {
    externalAuditEventDestinationDestroy: {
      errors,
    },
  },
});

export const destinationHeaderCreateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersCreate: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const destinationHeaderUpdateMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersUpdate: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const destinationHeaderDeleteMutationPopulator = (errors = []) => ({
  data: {
    auditEventsStreamingHeadersDestroy: {
      errors,
      clientMutationId: uniqueId(),
    },
  },
});

export const mockSvgPath = 'mock/path';
