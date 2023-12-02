import { shallowMount } from '@vue/test-utils';
import {
  member as memberMock,
  group,
  invite,
  accessRequest,
  bannedMember,
} from 'ee_else_ce_jest/members/mock_data';
import AccessRequestActionButtons from '~/members/components/action_buttons/access_request_action_buttons.vue';
import GroupActionButtons from '~/members/components/action_buttons/group_action_buttons.vue';
import InviteActionButtons from '~/members/components/action_buttons/invite_action_buttons.vue';
import UserActionButtons from '~/members/components/action_buttons/user_action_buttons.vue';
import MemberActionButtons from '~/members/components/table/member_action_buttons.vue';
import BannedActionButtons from 'ee/members/components/action_buttons/banned_action_buttons.vue';
import { MEMBER_TYPES } from 'ee_else_ce/members/constants';
import { stubComponent } from 'helpers/stub_component';

describe('MemberActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(MemberActionButtons, {
      stubs: { BannedActionButtons: stubComponent(BannedActionButtons) },
      propsData: {
        isCurrentUser: false,
        isInvitedUser: false,
        permissions: {
          canRemove: true,
        },
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    memberType                    | member           | expectedComponent             | expectedComponentName
    ${MEMBER_TYPES.user}          | ${memberMock}    | ${UserActionButtons}          | ${'UserActionButtons'}
    ${MEMBER_TYPES.group}         | ${group}         | ${GroupActionButtons}         | ${'GroupActionButtons'}
    ${MEMBER_TYPES.invite}        | ${invite}        | ${InviteActionButtons}        | ${'InviteActionButtons'}
    ${MEMBER_TYPES.accessRequest} | ${accessRequest} | ${AccessRequestActionButtons} | ${'AccessRequestActionButtons'}
    ${MEMBER_TYPES.banned}        | ${bannedMember}  | ${BannedActionButtons}        | ${'BannedActionButtons'}
  `(
    'renders $expectedComponentName when `memberType` is $memberType',
    ({ memberType, member, expectedComponent }) => {
      createComponent({ memberType, member });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    },
  );
});
