import MockAdapter from 'axios-mock-adapter';

import { statusType } from 'ee/epic/constants';
import * as actions from 'ee/epic/store/actions';
import defaultState from 'ee/epic/store/state';
import epicUtils from 'ee/epic/utils/epic_utils';

import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import axios from '~/lib/utils/axios_utils';

import { mockEpicMeta, mockEpicData } from '../mock_data';

jest.mock('~/flash');

describe('Epic Store Actions', () => {
  let state;

  beforeEach(() => {
    state = { ...defaultState() };
  });

  describe('setEpicMeta', () => {
    it('should set received Epic meta', async () => {
      await testAction(
        actions.setEpicMeta,
        mockEpicMeta,
        {},
        [{ type: 'SET_EPIC_META', payload: mockEpicMeta }],
        [],
      );
    });
  });

  describe('setEpicData', () => {
    it('should set received Epic data', async () => {
      await testAction(
        actions.setEpicData,
        mockEpicData,
        {},
        [{ type: 'SET_EPIC_DATA', payload: mockEpicData }],
        [],
      );
    });
  });

  describe('fetchEpicDetails', () => {
    let mock;

    const payload = {
      fullPath: 'gitlab-org',
      iid: 8,
    };

    const gqlQueryResponse = {
      group: {
        epic: {
          participants: {
            edges: [
              {
                node: {
                  name: 'Jane Doe',
                  avatarUrl: 'https://example.com/avatar/jane-doe.jpg',
                  webUrl: 'https://example.com/user/jane-doe.jpg',
                },
              },
              {
                node: {
                  name: 'John Doe',
                  avatarUrl: 'https://example.com/avatar/john-doe.jpg',
                  webUrl: 'https://example.com/user/john-doe.jpg',
                },
              },
            ],
          },
        },
      },
    };

    const formattedParticipants = [
      {
        name: 'Jane Doe',
        avatar_url: 'https://example.com/avatar/jane-doe.jpg',
        web_url: 'https://example.com/user/jane-doe.jpg',
      },
      {
        name: 'John Doe',
        avatar_url: 'https://example.com/avatar/john-doe.jpg',
        web_url: 'https://example.com/user/john-doe.jpg',
      },
    ];

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('dispatches setEpicData when request is successful', async () => {
      mock.onPut(/(.*)/).replyOnce(200, {});
      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
        Promise.resolve({
          data: gqlQueryResponse,
        }),
      );

      await testAction(
        actions.fetchEpicDetails,
        payload,
        state,
        [],
        [
          {
            type: 'setEpicData',
            payload: { participants: formattedParticipants },
          },
        ],
      );
    });

    it('dispatches requestEpicParticipantsFailure when request fails', async () => {
      mock.onPut(/(.*)/).replyOnce(500, {});
      jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(Promise.resolve({}));

      await testAction(
        actions.fetchEpicDetails,
        payload,
        state,
        [],
        [
          {
            type: 'requestEpicParticipantsFailure',
          },
        ],
      );
    });
  });

  describe('requestEpicParticipantsFailure', () => {
    it('does not invoke any mutations or actions', async () => {
      await testAction(actions.requestEpicParticipantsFailure, {}, state, [], []);
    });

    it('shows flash error', () => {
      actions.requestEpicParticipantsFailure({ commit: () => {} });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'There was an error getting the epic participants.',
      });
    });
  });

  describe('requestEpicStatusChange', () => {
    it('should set status change flag', async () => {
      await testAction(
        actions.requestEpicStatusChange,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE' }],
        [],
      );
    });
  });

  describe('requestEpicStatusChangeSuccess', () => {
    it('should set epic state type', async () => {
      await testAction(
        actions.requestEpicStatusChangeSuccess,
        { state: statusType.close },
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_SUCCESS', payload: { state: statusType.close } }],
        [],
      );
    });
  });

  describe('requestEpicStatusChangeFailure', () => {
    it('should set status change flag', async () => {
      await testAction(
        actions.requestEpicStatusChangeFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_FAILURE' }],
        [],
      );
    });

    it('should show flash error', () => {
      actions.requestEpicStatusChangeFailure({ commit: () => {} });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Unable to update this epic at this time.',
      });
    });
  });

  describe('triggerIssuableEvent', () => {
    it('Calls `triggerDocumentEvent` with events `issuable_vue_app:change`, `issuable:change` and passes `isEpicOpen` as param', () => {
      jest.spyOn(epicUtils, 'triggerDocumentEvent').mockReturnValue(false);

      const data = { isEpicOpen: true };
      actions.triggerIssuableEvent({}, data);

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        EVENT_ISSUABLE_VUE_APP_CHANGE,
        data.isEpicOpen,
      );

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        'issuable:change',
        data.isEpicOpen,
      );
    });
  });

  describe('toggleEpicStatus', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeSuccess when request is complete', async () => {
        mock.onPut(/(.*)/).replyOnce(200, {
          state: statusType.close,
        });

        await testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeSuccess',
              payload: { state: statusType.close },
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeFailure when request fails', async () => {
        mock.onPut(/(.*)/).replyOnce(500, {});

        await testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeFailure',
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
        );
      });
    });
  });

  describe('toggleSidebarFlag', () => {
    it('should call `TOGGLE_SIDEBAR` mutation with param `sidebarCollapsed`', async () => {
      const sidebarCollapsed = true;

      await testAction(
        actions.toggleSidebarFlag,
        sidebarCollapsed,
        state,
        [{ type: 'TOGGLE_SIDEBAR', payload: sidebarCollapsed }],
        [],
      );
    });
  });

  describe('toggleContainerClassAndCookie', () => {
    const sidebarCollapsed = true;

    beforeEach(() => {
      jest.spyOn(epicUtils, 'toggleContainerClass');
      jest.spyOn(epicUtils, 'setCollapsedGutter');
    });

    it('should call `epicUtils.toggleContainerClass` with classes `right-sidebar-expanded` & `right-sidebar-collapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.toggleContainerClass).toHaveBeenCalledTimes(2);
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-expanded');
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-collapsed');
    });

    it('should call `epicUtils.setCollapsedGutter` with param `isSidebarCollapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.setCollapsedGutter).toHaveBeenCalledWith(sidebarCollapsed);
    });
  });

  describe('toggleSidebar', () => {
    it('dispatches toggleContainerClassAndCookie and toggleSidebarFlag actions with opposite value of `isSidebarCollapsed` param', async () => {
      const sidebarCollapsed = true;

      await testAction(
        actions.toggleSidebar,
        { sidebarCollapsed },
        state,
        [],
        [
          {
            type: 'toggleContainerClassAndCookie',
            payload: !sidebarCollapsed,
          },
          {
            type: 'toggleSidebarFlag',
            payload: !sidebarCollapsed,
          },
        ],
      );
    });
  });

  describe('requestEpicTodoToggle', () => {
    it('should set `state.epicTodoToggleInProgress` flag to `true`', async () => {
      await testAction(
        actions.requestEpicTodoToggle,
        {},
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE' }],
        [],
      );
    });
  });

  describe('requestEpicTodoToggleSuccess', () => {
    it('should set epic state type', async () => {
      await testAction(
        actions.requestEpicTodoToggleSuccess,
        { todoDeletePath: '/foo/bar' },
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE_SUCCESS', payload: { todoDeletePath: '/foo/bar' } }],
        [],
      );
    });
  });

  describe('requestEpicTodoToggleFailure', () => {
    it('Should set `state.epicTodoToggleInProgress` flag to `false`', async () => {
      await testAction(
        actions.requestEpicTodoToggleFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE_FAILURE', payload: {} }],
        [],
      );
    });

    it('Should show flash error with message "There was an error deleting the To Do." when `state.todoExists` is `true`', () => {
      actions.requestEpicTodoToggleFailure(
        {
          commit: () => {},
          state: { todoExists: true },
        },
        {},
      );

      expect(createFlash).toHaveBeenCalledWith({
        message: 'There was an error deleting the To Do.',
      });
    });

    it('Should show flash error with message "There was an error adding a To Do." when `state.todoExists` is `false`', () => {
      actions.requestEpicTodoToggleFailure(
        {
          commit: () => {},
          state: { todoExists: false },
        },
        {},
      );

      expect(createFlash).toHaveBeenCalledWith({ message: 'There was an error adding a To Do.' });
    });
  });

  describe('triggerTodoToggleEvent', () => {
    it('Calls `triggerDocumentEvent` with event `todo:toggle` and passes `count` as param', () => {
      jest.spyOn(document, 'dispatchEvent').mockReturnValue(false);

      const data = { count: 5 };
      actions.triggerTodoToggleEvent({}, data);

      expect(document.dispatchEvent).toHaveBeenCalledWith(new CustomEvent('todo:toggle'));
    });
  });

  describe('toggleTodo', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when `state.togoExists` is false', () => {
      it('dispatches requestEpicTodoToggle, triggerTodoToggleEvent and requestEpicTodoToggleSuccess when request is successful', async () => {
        mock.onPost(/(.*)/).replyOnce(200, {
          count: 5,
          delete_path: '/foo/bar',
        });

        await testAction(
          actions.toggleTodo,
          null,
          { todoExists: false },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'triggerTodoToggleEvent',
              payload: { count: 5 },
            },
            {
              type: 'requestEpicTodoToggleSuccess',
              payload: { todoDeletePath: '/foo/bar' },
            },
          ],
        );
      });

      it('dispatches requestEpicTodoToggle and requestEpicTodoToggleFailure when request fails', async () => {
        mock.onPost(/(.*)/).replyOnce(500, {});

        await testAction(
          actions.toggleTodo,
          null,
          { todoExists: false },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'requestEpicTodoToggleFailure',
            },
          ],
        );
      });
    });

    describe('when `state.togoExists` is true', () => {
      it('dispatches requestEpicTodoToggle, triggerTodoToggleEvent and requestEpicTodoToggleSuccess when request is successful', async () => {
        mock.onDelete(/(.*)/).replyOnce(200, {
          count: 5,
        });

        await testAction(
          actions.toggleTodo,
          null,
          { todoExists: true },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'triggerTodoToggleEvent',
              payload: { count: 5 },
            },
            {
              type: 'requestEpicTodoToggleSuccess',
              payload: { todoDeletePath: undefined },
            },
          ],
        );
      });

      it('dispatches requestEpicTodoToggle and requestEpicTodoToggleFailure when request fails', async () => {
        mock.onDelete(/(.*)/).replyOnce(500, {});

        await testAction(
          actions.toggleTodo,
          null,
          { todoExists: true },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'requestEpicTodoToggleFailure',
            },
          ],
        );
      });
    });
  });

  describe('setEpicCreateTitle', () => {
    it('should set `state.newEpicTitle` value to the value of `newEpicTitle` param', async () => {
      const data = {
        newEpicTitle: 'foobar',
      };

      await testAction(
        actions.setEpicCreateTitle,
        data,
        { newEpicTitle: '' },
        [{ type: 'SET_EPIC_CREATE_TITLE', payload: { ...data } }],
        [],
      );
    });
  });

  describe('setEpicCreateConfidential', () => {
    it('should set `state.newEpicConfidential` value to the value of `newEpicConfidential` param', async () => {
      const data = {
        newEpicConfidential: true,
      };

      await testAction(
        actions.setEpicCreateConfidential,
        data,
        { newEpicConfidential: true },
        [{ type: 'SET_EPIC_CREATE_CONFIDENTIAL', payload: { ...data } }],
        [],
      );
    });
  });

  describe('requestEpicCreate', () => {
    it('should set `state.epicCreateInProgress` flag to `true`', async () => {
      await testAction(
        actions.requestEpicCreate,
        {},
        { epicCreateInProgress: false },
        [{ type: 'REQUEST_EPIC_CREATE' }],
        [],
      );
    });
  });

  describe('requestEpicCreateFailure', () => {
    it('should set `state.epicCreateInProgress` flag to `false`', async () => {
      await testAction(
        actions.requestEpicCreateFailure,
        {},
        { epicCreateInProgress: true },
        [{ type: 'REQUEST_EPIC_CREATE_FAILURE' }],
        [],
      );
    });

    it('should show flash error with message "Error creating epic."', () => {
      actions.requestEpicCreateFailure({
        commit: () => {},
      });

      expect(createFlash).toHaveBeenCalledWith({ message: 'Error creating epic' });
    });
  });

  describe('createEpic', () => {
    let mock;
    const stateCreateEpic = {
      newEpicTitle: 'foobar',
      newEpicConfidential: true,
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicCreate when request is complete', async () => {
        mock.onPost(/(.*)/).replyOnce(200, {});

        await testAction(
          actions.createEpic,
          { ...stateCreateEpic },
          stateCreateEpic,
          [],
          [
            {
              type: 'requestEpicCreate',
            },
            {
              type: 'requestEpicCreateSuccess',
            },
          ],
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicCreate and requestEpicCreateFailure when request fails', async () => {
        mock.onPost(/(.*)/).replyOnce(500, {});

        await testAction(
          actions.createEpic,
          { ...stateCreateEpic },
          stateCreateEpic,
          [],
          [
            {
              type: 'requestEpicCreate',
            },
            {
              type: 'requestEpicCreateFailure',
            },
          ],
        );
      });
    });
  });

  describe('updateConfidentialityOnIssuable', () => {
    it('should commit `SET_EPIC_CONFIDENTIAL` mutation with param `sidebarCollapsed', async () => {
      const confidential = true;
      await testAction(
        actions.updateConfidentialityOnIssuable,
        confidential,
        state,
        [{ payload: true, type: 'SET_EPIC_CONFIDENTIAL' }],
        [],
      );
    });
  });
});
