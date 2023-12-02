import Vue, { nextTick } from 'vue';
import { GlButton, GlDropdownItem, GlLink, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import createFlash, { FLASH_TYPES } from '~/flash';
import { IssuableStatus, IssueType } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import HeaderActions from '~/issues/show/components/header_actions.vue';
import { ISSUE_STATE_EVENT_CLOSE, ISSUE_STATE_EVENT_REOPEN } from '~/issues/show/constants';
import promoteToEpicMutation from '~/issues/show/queries/promote_to_epic.mutation.graphql';
import * as urlUtility from '~/lib/utils/url_utility';
import eventHub from '~/notes/event_hub';
import createStore from '~/notes/stores';

jest.mock('~/flash');

describe('HeaderActions component', () => {
  let dispatchEventSpy;
  let mutateMock;
  let wrapper;
  let visitUrlSpy;

  Vue.use(Vuex);

  const store = createStore();

  const defaultProps = {
    canCreateIssue: true,
    canDestroyIssue: true,
    canPromoteToEpic: true,
    canReopenIssue: true,
    canReportSpam: true,
    canUpdateIssue: true,
    iid: '32',
    isIssueAuthor: true,
    issuePath: 'gitlab-org/gitlab-test/-/issues/1',
    issueType: IssueType.Issue,
    newIssuePath: 'gitlab-org/gitlab-test/-/issues/new',
    projectPath: 'gitlab-org/gitlab-test',
    reportAbusePath:
      '-/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%2Fgitlab-org%2Fgitlab-test%2F-%2Fissues%2F32&user_id=1',
    submitAsSpamPath: 'gitlab-org/gitlab-test/-/issues/32/submit_as_spam',
  };

  const updateIssueMutationResponse = { data: { updateIssue: { errors: [] } } };

  const promoteToEpicMutationResponse = {
    data: {
      promoteToEpic: {
        errors: [],
        epic: {
          webPath: '/groups/gitlab-org/-/epics/1',
        },
      },
    },
  };

  const promoteToEpicMutationErrorResponse = {
    data: {
      promoteToEpic: {
        errors: ['The issue has already been promoted to an epic.'],
        epic: {},
      },
    },
  };

  const findToggleIssueStateButton = () => wrapper.findComponent(GlButton);

  const findDropdownBy = (dataTestId) => wrapper.find(`[data-testid="${dataTestId}"]`);
  const findMobileDropdown = () => findDropdownBy('mobile-dropdown');
  const findDesktopDropdown = () => findDropdownBy('desktop-dropdown');
  const findMobileDropdownItems = () => findMobileDropdown().findAllComponents(GlDropdownItem);
  const findDesktopDropdownItems = () => findDesktopDropdown().findAllComponents(GlDropdownItem);

  const findModal = () => wrapper.findComponent(GlModal);

  const findModalLinkAt = (index) => findModal().findAllComponents(GlLink).at(index);

  const mountComponent = ({
    props = {},
    issueState = IssuableStatus.Open,
    blockedByIssues = [],
    mutateResponse = {},
  } = {}) => {
    mutateMock = jest.fn().mockResolvedValue(mutateResponse);

    store.dispatch('setNoteableData', {
      blocked_by_issues: blockedByIssues,
      state: issueState,
    });

    return shallowMount(HeaderActions, {
      store,
      provide: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $apollo: {
          mutate: mutateMock,
        },
      },
    });
  };

  afterEach(() => {
    if (dispatchEventSpy) {
      dispatchEventSpy.mockRestore();
    }
    if (visitUrlSpy) {
      visitUrlSpy.mockRestore();
    }
    wrapper.destroy();
  });

  describe.each`
    issueType
    ${IssueType.Issue}
    ${IssueType.Incident}
  `('when issue type is $issueType', ({ issueType }) => {
    describe('close/reopen button', () => {
      describe.each`
        description                          | issueState               | buttonText               | newIssueState
        ${`when the ${issueType} is open`}   | ${IssuableStatus.Open}   | ${`Close ${issueType}`}  | ${ISSUE_STATE_EVENT_CLOSE}
        ${`when the ${issueType} is closed`} | ${IssuableStatus.Closed} | ${`Reopen ${issueType}`} | ${ISSUE_STATE_EVENT_REOPEN}
      `('$description', ({ issueState, buttonText, newIssueState }) => {
        beforeEach(() => {
          dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

          wrapper = mountComponent({
            props: { issueType },
            issueState,
            mutateResponse: updateIssueMutationResponse,
          });
        });

        it(`has text "${buttonText}"`, () => {
          expect(findToggleIssueStateButton().text()).toBe(buttonText);
        });

        it('calls apollo mutation', () => {
          findToggleIssueStateButton().vm.$emit('click');

          expect(mutateMock).toHaveBeenCalledWith(
            expect.objectContaining({
              variables: {
                input: {
                  iid: defaultProps.iid,
                  projectPath: defaultProps.projectPath,
                  stateEvent: newIssueState,
                },
              },
            }),
          );
        });

        it('dispatches a custom event to update the issue page', async () => {
          findToggleIssueStateButton().vm.$emit('click');

          await nextTick();

          expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe.each`
      description           | isCloseIssueItemVisible | findDropdownItems           | findDropdown
      ${'mobile dropdown'}  | ${true}                 | ${findMobileDropdownItems}  | ${findMobileDropdown}
      ${'desktop dropdown'} | ${false}                | ${findDesktopDropdownItems} | ${findDesktopDropdown}
    `('$description', ({ isCloseIssueItemVisible, findDropdownItems, findDropdown }) => {
      describe.each`
        description                               | itemText                      | isItemVisible              | canUpdateIssue | canCreateIssue | isIssueAuthor | canReportSpam | canPromoteToEpic | canDestroyIssue
        ${`when user can update ${issueType}`}    | ${`Close ${issueType}`}       | ${isCloseIssueItemVisible} | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot update ${issueType}`} | ${`Close ${issueType}`}       | ${false}                   | ${false}       | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user can create ${issueType}`}    | ${`New related ${issueType}`} | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot create ${issueType}`} | ${`New related ${issueType}`} | ${false}                   | ${true}        | ${false}       | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can promote to epic'}        | ${'Promote to epic'}          | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot promote to epic'}     | ${'Promote to epic'}          | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${false}         | ${true}
        ${'when user can report abuse'}           | ${'Report abuse'}             | ${true}                    | ${true}        | ${true}        | ${false}      | ${true}       | ${true}          | ${true}
        ${'when user cannot report abuse'}        | ${'Report abuse'}             | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user can submit as spam'}         | ${'Submit as spam'}           | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${'when user cannot submit as spam'}      | ${'Submit as spam'}           | ${false}                   | ${true}        | ${true}        | ${true}       | ${false}      | ${true}          | ${true}
        ${`when user can delete ${issueType}`}    | ${`Delete ${issueType}`}      | ${true}                    | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${true}
        ${`when user cannot delete ${issueType}`} | ${`Delete ${issueType}`}      | ${false}                   | ${true}        | ${true}        | ${true}       | ${true}       | ${true}          | ${false}
      `(
        '$description',
        ({
          itemText,
          isItemVisible,
          canUpdateIssue,
          canCreateIssue,
          isIssueAuthor,
          canReportSpam,
          canPromoteToEpic,
          canDestroyIssue,
        }) => {
          beforeEach(() => {
            wrapper = mountComponent({
              props: {
                canUpdateIssue,
                canCreateIssue,
                isIssueAuthor,
                issueType,
                canReportSpam,
                canPromoteToEpic,
                canDestroyIssue,
              },
            });
          });

          it(`${isItemVisible ? 'shows' : 'hides'} "${itemText}" item`, () => {
            expect(
              findDropdownItems()
                .filter((item) => item.text() === itemText)
                .exists(),
            ).toBe(isItemVisible);
          });
        },
      );

      describe(`when user can update but not create ${issueType}`, () => {
        beforeEach(() => {
          wrapper = mountComponent({
            props: {
              canUpdateIssue: true,
              canCreateIssue: false,
              isIssueAuthor: true,
              issueType,
              canReportSpam: false,
              canPromoteToEpic: false,
            },
          });
        });
        it(`${isCloseIssueItemVisible ? 'shows' : 'hides'} the dropdown button`, () => {
          expect(findDropdown().exists()).toBe(isCloseIssueItemVisible);
        });
      });
    });
  });

  describe('delete issue button', () => {
    let trackingSpy;

    beforeEach(() => {
      wrapper = mountComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('tracks clicking on button', () => {
      findDesktopDropdownItems().at(3).vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_dropdown', {
        label: 'delete_issue',
      });
    });
  });

  describe('when "Promote to epic" button is clicked', () => {
    describe('when response is successful', () => {
      beforeEach(() => {
        visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

        wrapper = mountComponent({
          mutateResponse: promoteToEpicMutationResponse,
        });

        wrapper.find('[data-testid="promote-button"]').vm.$emit('click');
      });

      it('invokes GraphQL mutation when clicked', () => {
        expect(mutateMock).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: promoteToEpicMutation,
            variables: {
              input: {
                iid: defaultProps.iid,
                projectPath: defaultProps.projectPath,
              },
            },
          }),
        );
      });

      it('shows a success message and tells the user they are being redirected', () => {
        expect(createFlash).toHaveBeenCalledWith({
          message: 'The issue was successfully promoted to an epic. Redirecting to epic...',
          type: FLASH_TYPES.SUCCESS,
        });
      });

      it('redirects to newly created epic path', () => {
        expect(visitUrlSpy).toHaveBeenCalledWith(
          promoteToEpicMutationResponse.data.promoteToEpic.epic.webPath,
        );
      });
    });

    describe('when response contains errors', () => {
      beforeEach(() => {
        visitUrlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

        wrapper = mountComponent({
          mutateResponse: promoteToEpicMutationErrorResponse,
        });

        wrapper.find('[data-testid="promote-button"]').vm.$emit('click');
      });

      it('shows an error message', () => {
        expect(createFlash).toHaveBeenCalledWith({
          message: HeaderActions.i18n.promoteErrorMessage,
        });
      });
    });
  });

  describe('when `toggle.issuable.state` event is emitted', () => {
    it('invokes a method to toggle the issue state', () => {
      wrapper = mountComponent({ mutateResponse: updateIssueMutationResponse });

      eventHub.$emit('toggle.issuable.state');

      expect(mutateMock).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              iid: defaultProps.iid,
              projectPath: defaultProps.projectPath,
              stateEvent: ISSUE_STATE_EVENT_CLOSE,
            },
          },
        }),
      );
    });
  });

  describe('blocked by issues modal', () => {
    const blockedByIssues = [
      { iid: 13, web_url: 'gitlab-org/gitlab-test/-/issues/13' },
      { iid: 79, web_url: 'gitlab-org/gitlab-test/-/issues/79' },
    ];

    beforeEach(() => {
      wrapper = mountComponent({ blockedByIssues });
    });

    it('has title text', () => {
      expect(findModal().attributes('title')).toBe(
        'Are you sure you want to close this blocked issue?',
      );
    });

    it('has body text', () => {
      expect(findModal().text()).toContain(
        'This issue is currently blocked by the following issues:',
      );
    });

    it('calls apollo mutation when primary button is clicked', () => {
      findModal().vm.$emit('primary');

      expect(mutateMock).toHaveBeenCalledWith(
        expect.objectContaining({
          variables: {
            input: {
              iid: defaultProps.iid.toString(),
              projectPath: defaultProps.projectPath,
              stateEvent: ISSUE_STATE_EVENT_CLOSE,
            },
          },
        }),
      );
    });

    describe.each`
      ordinal     | index
      ${'first'}  | ${0}
      ${'second'} | ${1}
    `('$ordinal blocked-by issue link', ({ index }) => {
      it('has link text', () => {
        expect(findModalLinkAt(index).text()).toBe(`#${blockedByIssues[index].iid}`);
      });

      it('has url', () => {
        expect(findModalLinkAt(index).attributes('href')).toBe(blockedByIssues[index].web_url);
      });
    });
  });

  describe('delete issue modal', () => {
    it('renders', () => {
      wrapper = mountComponent();

      expect(wrapper.findComponent(DeleteIssueModal).props()).toEqual({
        issuePath: defaultProps.issuePath,
        issueType: defaultProps.issueType,
        modalId: HeaderActions.deleteModalId,
        title: 'Delete issue',
      });
    });
  });
});
