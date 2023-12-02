import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  CREATED,
  MANUAL_DEPLOY,
  FAILED,
  DEPLOYING,
  REDEPLOYING,
  STOPPING,
} from '~/vue_merge_request_widget/components/deployment/constants';
import DeploymentActions from '~/vue_merge_request_widget/components/deployment/deployment_actions.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import {
  actionButtonMocks,
  deploymentMockData,
  playDetails,
  retryDetails,
} from './deployment_mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => {
  return {
    confirmAction: jest.fn(),
  };
});

describe('DeploymentAction component', () => {
  let wrapper;
  let executeActionSpy;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }

    wrapper = mount(DeploymentActions, options);
  };

  const findStopButton = () => wrapper.find('.js-stop-env');
  const findDeployButton = () => wrapper.find('.js-manual-deploy-action');
  const findRedeployButton = () => wrapper.find('.js-manual-redeploy-action');

  beforeEach(() => {
    executeActionSpy = jest.spyOn(MRWidgetService, 'executeInlineAction');

    factory({
      propsData: {
        computedDeploymentStatus: CREATED,
        deployment: deploymentMockData,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    confirmAction.mockReset();
  });

  describe('actions do not appear when conditions are unmet', () => {
    describe('when there is no stop_url', () => {
      beforeEach(() => {
        factory({
          propsData: {
            computedDeploymentStatus: CREATED,
            deployment: {
              ...deploymentMockData,
              stop_url: null,
            },
          },
        });
      });

      it('the stop button does not appear', () => {
        expect(findStopButton().exists()).toBe(false);
      });
    });

    describe('when there is no play_path in details', () => {
      it('the manual deploy button does not appear', () => {
        expect(findDeployButton().exists()).toBe(false);
      });
    });

    describe('when there is no retry_path in details', () => {
      it('the manual redeploy button does not appear', () => {
        expect(findRedeployButton().exists()).toBe(false);
      });
    });
  });

  describe('when conditions are met', () => {
    describe.each`
      configConst    | computedDeploymentStatus | displayConditionChanges | finderFn              | endpoint
      ${STOPPING}    | ${CREATED}               | ${{}}                   | ${findStopButton}     | ${deploymentMockData.stop_url}
      ${DEPLOYING}   | ${MANUAL_DEPLOY}         | ${playDetails}          | ${findDeployButton}   | ${playDetails.playable_build.play_path}
      ${REDEPLOYING} | ${FAILED}                | ${retryDetails}         | ${findRedeployButton} | ${retryDetails.playable_build.retry_path}
    `(
      '$configConst action',
      ({ configConst, computedDeploymentStatus, displayConditionChanges, finderFn, endpoint }) => {
        describe(`${configConst} action`, () => {
          beforeEach(() => {
            factory({
              propsData: {
                computedDeploymentStatus,
                deployment: {
                  ...deploymentMockData,
                  details: displayConditionChanges,
                },
              },
            });
          });

          it('the button is rendered', () => {
            expect(finderFn().exists()).toBe(true);
          });

          describe('when clicked', () => {
            describe('should show a confirm dialog but not call executeInlineAction when declined', () => {
              beforeEach(() => {
                executeActionSpy.mockResolvedValueOnce();
                confirmAction.mockResolvedValueOnce(false);
                finderFn().trigger('click');
              });

              it('should show the confirm dialog', () => {
                expect(confirmAction).toHaveBeenCalled();
                expect(confirmAction).toHaveBeenCalledWith(
                  actionButtonMocks[configConst].confirmMessage,
                  {
                    primaryBtnVariant: actionButtonMocks[configConst].buttonVariant,
                    primaryBtnText: actionButtonMocks[configConst].buttonText,
                  },
                );
              });

              it('should not execute the action', () => {
                expect(MRWidgetService.executeInlineAction).not.toHaveBeenCalled();
              });
            });

            describe('should show a confirm dialog and call executeInlineAction when accepted', () => {
              beforeEach(() => {
                executeActionSpy.mockResolvedValueOnce();
                confirmAction.mockResolvedValueOnce(true);
                finderFn().trigger('click');
              });

              it('should show the confirm dialog', () => {
                expect(confirmAction).toHaveBeenCalled();
                expect(confirmAction).toHaveBeenCalledWith(
                  actionButtonMocks[configConst].confirmMessage,
                  {
                    primaryBtnVariant: actionButtonMocks[configConst].buttonVariant,
                    primaryBtnText: actionButtonMocks[configConst].buttonText,
                  },
                );
              });

              it('should execute the action with expected URL', () => {
                expect(MRWidgetService.executeInlineAction).toHaveBeenCalled();
                expect(MRWidgetService.executeInlineAction).toHaveBeenCalledWith(endpoint);
              });

              it('should not throw an error', () => {
                expect(createFlash).not.toHaveBeenCalled();
              });

              describe('response includes redirect_url', () => {
                const url = '/root/example';
                beforeEach(async () => {
                  executeActionSpy.mockResolvedValueOnce({
                    data: { redirect_url: url },
                  });

                  await waitForPromises();

                  confirmAction.mockResolvedValueOnce(true);
                  finderFn().trigger('click');
                });

                it('calls visit url with the redirect_url', () => {
                  expect(visitUrl).toHaveBeenCalled();
                  expect(visitUrl).toHaveBeenCalledWith(url);
                });
              });

              describe('it should call the executeAction method', () => {
                beforeEach(async () => {
                  jest.spyOn(wrapper.vm, 'executeAction').mockImplementation();

                  await waitForPromises();

                  confirmAction.mockResolvedValueOnce(true);
                  finderFn().trigger('click');
                });

                it('calls with the expected arguments', () => {
                  expect(wrapper.vm.executeAction).toHaveBeenCalled();
                  expect(wrapper.vm.executeAction).toHaveBeenCalledWith(
                    endpoint,
                    actionButtonMocks[configConst],
                  );
                });
              });

              describe('when executeInlineAction errors', () => {
                beforeEach(async () => {
                  executeActionSpy.mockRejectedValueOnce();

                  await waitForPromises();

                  confirmAction.mockResolvedValueOnce(true);
                  finderFn().trigger('click');
                });

                it('should call createFlash with error message', () => {
                  expect(createFlash).toHaveBeenCalled();
                  expect(createFlash).toHaveBeenCalledWith({
                    message: actionButtonMocks[configConst].errorMessage,
                  });
                });
              });
            });
          });
        });
      },
    );
  });
});
