import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import MembersTableCell from 'ee/members/components/table/members_table_cell.vue';
import {
  member as memberMock,
  directMember,
  bannedMember,
} from 'ee_else_ce_jest/members/mock_data';
import { MEMBER_TYPES } from 'ee_else_ce/members/constants';

describe('MemberTableCell', () => {
  const WrappedComponent = {
    props: {
      memberType: {
        type: String,
        required: true,
      },
      isDirectMember: {
        type: Boolean,
        required: true,
      },
      isCurrentUser: {
        type: Boolean,
        required: true,
      },
      permissions: {
        type: Object,
        required: true,
      },
    },
    render(createElement) {
      return createElement('div', this.memberType);
    },
  };

  Vue.use(Vuex);
  Vue.component('WrappedComponent', WrappedComponent);

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state,
    });
  };

  let wrapper;

  const createComponent = (propsData, provide = {}) => {
    wrapper = mount(MembersTableCell, {
      propsData,
      store: createStore(),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        namespace: MEMBER_TYPES.user,
        ...provide,
      },
      scopedSlots: {
        default: `
          <wrapped-component
            :member-type="props.memberType"
            :is-direct-member="props.isDirectMember"
            :is-current-user="props.isCurrentUser"
            :permissions="props.permissions"
          />
        `,
      },
    });
  };

  const findWrappedComponent = () => wrapper.findComponent(WrappedComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  // Implementation of props are tested in `spec/frontend/vue_shared/components/members/table/members_table_spec.js`
  it('exposes CE scoped slot props', () => {
    createComponent({ member: memberMock });

    expect(findWrappedComponent().props()).toMatchSnapshot();
  });

  describe('permissions', () => {
    describe('canOverride', () => {
      it('returns `true` when `canOverride` is `true`', () => {
        createComponent({
          member: { ...directMember, canOverride: true },
        });

        expect(findWrappedComponent().props('permissions').canOverride).toBe(true);
      });

      it('returns `false` when `canOverride` is `false`', () => {
        createComponent({
          member: { ...directMember, canOverride: false },
        });

        expect(findWrappedComponent().props('permissions').canOverride).toBe(false);
      });
    });

    describe('canUnban', () => {
      it('returns `true` when member is banned and `canUnban` is `true`', () => {
        createComponent({
          member: { ...bannedMember, canUnban: true },
        });

        expect(findWrappedComponent().props('permissions').canUnban).toBe(true);
      });

      it('returns `false` when member is not banned', () => {
        createComponent({
          member: { ...directMember, canUnban: true },
        });

        expect(findWrappedComponent().props('permissions').canUnban).toBe(false);
      });

      it('returns `false` when `canUnban` is false', () => {
        createComponent({
          member: { ...bannedMember, canUnban: false },
        });

        expect(findWrappedComponent().props('permissions').canUnban).toBe(false);
      });
    });
  });

  describe('memberType', () => {
    it('has memberType value from CE when user is not banned', () => {
      createComponent({ member: directMember }, { namespace: MEMBER_TYPES.banned });

      expect(findWrappedComponent().props('memberType')).not.toEqual(MEMBER_TYPES.banned);
    });

    it('has memberType value from CE when namespace is not banned', () => {
      createComponent({ member: directMember });

      expect(findWrappedComponent().props('memberType')).not.toEqual(MEMBER_TYPES.banned);
    });

    it('is `MEMBER_TYPES.banned` when namespace is `MEMBER_TYPES.banned` and user is banned', () => {
      createComponent({ member: bannedMember }, { namespace: MEMBER_TYPES.banned });

      expect(findWrappedComponent().props('memberType')).toEqual(MEMBER_TYPES.banned);
    });
  });
});
