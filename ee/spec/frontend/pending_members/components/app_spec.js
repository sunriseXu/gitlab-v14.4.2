import { GlPagination, GlBadge, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { mockDataMembers, mockInvitedApprovedMember } from 'ee_jest/pending_members/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PendingMembersApp from 'ee/pending_members/components/app.vue';

Vue.use(Vuex);

const actionSpies = {
  fetchPendingMembersList: jest.fn(),
};

const providedFields = {
  namespaceId: '1000',
  namespaceName: 'Test Group Name',
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockDataMembers.data,
      ...initialGetters,
    },
    state: {
      isLoading: false,
      hasError: false,
      namespaceId: 1,
      members: mockDataMembers.data,
      total: 300,
      page: 1,
      perPage: 5,
      ...providedFields,
      ...initialState,
    },
  });

describe('PendingMembersApp', () => {
  let wrapper;

  const createComponent = ({ initialState = {}, initialGetters = {}, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PendingMembersApp, {
        store: fakeStore({ initialState, initialGetters }),
        stubs,
      }),
    );
  };

  const findMemberRows = () => wrapper.findAllByTestId('pending-members-row');
  const findPagination = () => wrapper.findComponent(GlPagination);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders pending members', () => {
    const memberRows = findMemberRows();

    expect(memberRows.length).toBe(mockDataMembers.data.length);
    expect(findMemberRows().wrappers.map((w) => w.html())).toMatchSnapshot();
  });

  it('pagination is rendered and passed correct values', () => {
    const pagination = findPagination();

    expect(pagination.props()).toMatchObject({
      perPage: 5,
      totalItems: 300,
    });
  });

  it('render badge for approved invited members', () => {
    createComponent({
      stubs: { GlBadge, GlAvatarLabeled },
      initialGetters: { tableItems: () => [mockInvitedApprovedMember] },
      initialState: { members: [mockInvitedApprovedMember] },
    });
    expect(wrapper.findComponent(GlBadge).text()).toEqual('Awaiting member signup');
  });
});
