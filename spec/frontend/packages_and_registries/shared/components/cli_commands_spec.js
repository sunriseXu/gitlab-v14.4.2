import { GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import QuickstartDropdown from '~/packages_and_registries/shared/components/cli_commands.vue';
import {
  QUICK_START,
  LOGIN_COMMAND_LABEL,
  COPY_LOGIN_TITLE,
  BUILD_COMMAND_LABEL,
  COPY_BUILD_TITLE,
  PUSH_COMMAND_LABEL,
  COPY_PUSH_TITLE,
} from '~/packages_and_registries/container_registry/explorer/constants';
import Tracking from '~/tracking';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

import { dockerCommands } from 'jest/packages_and_registries/container_registry/explorer/mock_data';

Vue.use(Vuex);

describe('cli_commands', () => {
  let wrapper;

  const findDropdownButton = () => wrapper.findComponent(GlDropdown);
  const findCodeInstruction = () => wrapper.findAllComponents(CodeInstruction);

  const mountComponent = () => {
    wrapper = mount(QuickstartDropdown, {
      propsData: {
        ...dockerCommands,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('shows the correct text on the button', () => {
    expect(findDropdownButton().text()).toContain(QUICK_START);
  });

  it('clicking on the dropdown emit a tracking event', () => {
    findDropdownButton().vm.$emit('shown');
    expect(Tracking.event).toHaveBeenCalledWith(
      undefined,
      'click_dropdown',
      expect.objectContaining({ label: 'quickstart_dropdown' }),
    );
  });

  describe.each`
    index | labelText              | titleText           | command                              | trackedEvent
    ${0}  | ${LOGIN_COMMAND_LABEL} | ${COPY_LOGIN_TITLE} | ${dockerCommands.dockerLoginCommand} | ${'click_copy_login'}
    ${1}  | ${BUILD_COMMAND_LABEL} | ${COPY_BUILD_TITLE} | ${dockerCommands.dockerBuildCommand} | ${'click_copy_build'}
    ${2}  | ${PUSH_COMMAND_LABEL}  | ${COPY_PUSH_TITLE}  | ${dockerCommands.dockerPushCommand}  | ${'click_copy_push'}
  `('code instructions at $index', ({ index, labelText, titleText, command, trackedEvent }) => {
    let codeInstruction;

    beforeEach(() => {
      codeInstruction = findCodeInstruction().at(index);
    });

    it('exists', () => {
      expect(codeInstruction.exists()).toBe(true);
    });

    it(`has the correct props`, () => {
      expect(codeInstruction.props()).toMatchObject({
        label: labelText,
        instruction: command,
        copyText: titleText,
        trackingAction: trackedEvent,
        trackingLabel: 'quickstart_dropdown',
      });
    });
  });
});
