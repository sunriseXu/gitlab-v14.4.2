import { GlButton, GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EnvironmentApproval from 'ee/environments/components/environment_approval.vue';
import Api from 'ee/api';
import { __, s__, sprintf } from '~/locale';
import { createAlert } from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { environment as mockEnvironment } from './mock_data';

jest.mock('ee/api.js');
jest.mock('~/flash');

describe('ee/environments/components/environment_approval.vue', () => {
  let wrapper;

  const environment = convertObjectPropsToCamelCase(mockEnvironment, { deep: true });

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(EnvironmentApproval, {
      propsData: { environment, ...propsData },
      provide: { projectId: '5' },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => extendedWrapper(wrapper.findComponent(GlModal));
  const findButton = () => extendedWrapper(wrapper.findComponent(GlButton));

  const setComment = (comment) =>
    wrapper
      .findByRole('textbox', { name: (content) => content.startsWith(__('Comment')) })
      .setValue(comment);

  describe('button', () => {
    it('shows the button so long as the environment has approvals', () => {
      wrapper = createWrapper();
      expect(findButton().exists()).toBe(true);
    });

    it('shows the button while the deployment still needs approving', () => {
      wrapper = createWrapper({
        propsData: {
          environment: {
            ...environment,
            upcomingDeployment: {
              ...environment.upcomingDeployment,
              approvals: [],
            },
          },
        },
      });

      expect(findButton().exists()).toBe(true);
    });

    it('hides the button if no approvals were required (a deployment happened before the environment was protected)', () => {
      wrapper = createWrapper({
        propsData: {
          environment: {
            ...environment,
            requiredApprovalCount: 3,
            upcomingDeployment: {
              ...environment.upcomingDeployment,
              approvals: [],
              pendingApprovalCount: 0,
            },
          },
        },
      });

      expect(findButton().exists()).toBe(false);
    });
  });

  describe('modal', () => {
    let modal;

    beforeEach(async () => {
      wrapper = createWrapper();
      await findButton().trigger('click');
      modal = findModal();
    });

    it('should set the modal title', () => {
      expect(modal.props('title')).toBe(
        sprintf(s__('DeploymentApproval|Approve or reject deployment #%{deploymentIid}'), {
          deploymentIid: environment.upcomingDeployment.iid,
        }),
      );
    });

    it('should show the modal after clicking the button', () => {
      expect(modal.props('visible')).toBe(true);
    });

    it('should show which deployment this is approving', () => {
      const main = sprintf(
        s__(
          'DeploymentApproval|Approving will run the manual job from deployment #%{deploymentIid}. Rejecting will fail the manual job.',
        ),
        {
          deploymentIid: environment.upcomingDeployment.iid,
        },
      );
      expect(modal.findByText(main).exists()).toBe(true);
    });

    describe('showing details about the environment', () => {
      it.each`
        detail                | text
        ${'environment name'} | ${sprintf(s__('DeploymentApproval|Environment: %{environment}'), { environment: environment.name })}
        ${'environment tier'} | ${sprintf(s__('DeploymentApproval|Deployment tier: %{tier}'), { tier: environment.tier })}
        ${'job name'}         | ${sprintf(s__('DeploymentApproval|Manual job: %{jobName}'), { jobName: environment.upcomingDeployment.deployable.name })}
      `('should show information on $detail', ({ text }) => {
        expect(trimText(modal.text())).toContain(text);
      });

      it('shows the number of current approvals as well as the number of total approvals needed', () => {
        expect(trimText(modal.text())).toContain(
          sprintf(s__('DeploymentApproval| Current approvals: %{current}'), {
            current: '5/10',
          }),
        );
      });
    });

    describe('comment', () => {
      const max = 250;
      const closeToFull = Array(max - 30)
        .fill('a')
        .join('');
      const full = Array(max).fill('a').join('');
      const over = Array(max + 1)
        .fill('a')
        .join('');

      it.each`
        comment        | tooltip                        | classes
        ${'hello'}     | ${__('Characters left')}       | ${{ 'gl-text-orange-500': false, 'gl-text-red-500': false }}
        ${closeToFull} | ${__('Characters left')}       | ${{ 'gl-text-orange-500': true, 'gl-text-red-500': false }}
        ${full}        | ${__('Characters left')}       | ${{ 'gl-text-orange-500': true, 'gl-text-red-500': false }}
        ${over}        | ${__('Characters over limit')} | ${{ 'gl-text-orange-500': false, 'gl-text-red-500': true }}
      `(
        'shows remaining length with tooltip $tooltip when comment length is $comment.length, coloured appropriately',
        async ({ comment, tooltip, classes }) => {
          await setComment(comment);

          const counter = wrapper.findByTitle(tooltip);

          expect(counter.text()).toBe((max - comment.length).toString());

          Object.entries(classes).forEach(([klass, present]) => {
            if (present) {
              expect(counter.classes()).toContain(klass);
            } else {
              expect(counter.classes()).not.toContain(klass);
            }
          });
        },
      );
    });

    describe('permissions', () => {
      beforeAll(() => {
        gon.current_username = 'root';
      });

      it.each`
        scenario                                       | username  | approvals                                                  | canApproveDeployment | visible
        ${'user can approve, no approvals'}            | ${'root'} | ${[]}                                                      | ${true}              | ${true}
        ${'user cannot approve, no approvals'}         | ${'root'} | ${[]}                                                      | ${false}             | ${false}
        ${'user can approve, has approved'}            | ${'root'} | ${[{ user: { username: 'root' }, createdAt: Date.now() }]} | ${true}              | ${false}
        ${'user can approve, someone else approved'}   | ${'root'} | ${[{ user: { username: 'foo' }, createdAt: Date.now() }]}  | ${true}              | ${true}
        ${'user cannot approve, has already approved'} | ${'root'} | ${[{ user: { username: 'root' }, createdAt: Date.now() }]} | ${false}             | ${false}
      `(
        'should have buttons visible when $scenario: $visible',
        async ({ approvals, canApproveDeployment, visible }) => {
          wrapper = createWrapper({
            propsData: {
              environment: {
                ...environment,
                upcomingDeployment: {
                  ...environment.upcomingDeployment,
                  approvals,
                  canApproveDeployment,
                },
              },
            },
          });

          await findButton().trigger('click');

          await nextTick();

          modal = findModal();

          expect(modal.findByRole('button', { name: __('Approve') }).exists()).toBe(visible);
          expect(modal.findByRole('button', { name: __('Reject') }).exists()).toBe(visible);
          expect(modal.findByRole('button', { name: __('Cancel') }).exists()).toBe(!visible);
        },
      );
    });

    describe.each`
      ref          | api                      | text
      ${'approve'} | ${Api.approveDeployment} | ${__('Approve')}
      ${'reject'}  | ${Api.rejectDeployment}  | ${__('Reject')}
    `('$ref', ({ ref, api, text }) => {
      let button;

      beforeEach(() => {
        button = wrapper.findByRole('button', { name: text });
      });

      it('should show the correct text', () => {
        expect(button.text()).toBe(text);
      });

      it(`should ${ref} the deployment when ${text} is clicked`, async () => {
        api.mockResolvedValue();

        setComment('comment');

        await button.trigger('click');

        expect(api).toHaveBeenCalledWith({
          id: '5',
          deploymentId: environment.upcomingDeployment.id,
          comment: 'comment',
        });

        await waitForPromises();

        expect(wrapper.emitted('change')).toEqual([[]]);
      });

      it('should show an error on failure', async () => {
        api.mockRejectedValue({ response: { data: { message: 'oops' } } });

        await button.trigger('click');
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({ message: 'oops' });
      });

      it('should set loading to true after click', async () => {
        await button.trigger('click');

        expect(findButton().props('loading')).toBe(true);
      });

      it('should stop showing the modal once resolved', async () => {
        api.mockResolvedValue();

        await button.trigger('click');

        expect(modal.props('visible')).toBe(false);
      });
    });
  });

  describe('showing text', () => {
    it('should show text by default', () => {
      wrapper = createWrapper();
      const button = findButton();

      expect(button.text()).toBe(s__('DeploymentApproval|Approval options'));
    });

    it('should hide the text if show text is false, and put it in the title', () => {
      wrapper = createWrapper({ propsData: { showText: false } });
      const button = findButton();

      expect(button.text()).toBe('');
      expect(button.attributes('title')).toBe(s__('DeploymentApproval|Approval options'));
    });
  });

  describe.each([
    { status: 'approved', text: 'Approved' },
    { status: 'rejected', text: 'Rejected' },
  ])('showing approvals that have been $status', ({ status, text }) => {
    const approval = environment.upcomingDeployment.approvals[0];

    beforeEach(async () => {
      wrapper = createWrapper({
        propsData: {
          environment: {
            ...environment,
            upcomingDeployment: {
              ...environment.upcomingDeployment,
              approvals: [{ ...approval, status }],
            },
          },
        },
      });
      await findButton().trigger('click');
    });

    it(`should show the avatar for who ${status} the deployment`, () => {
      const avatar = wrapper.findByRole('img', { name: 'avatar' });

      expect(avatar.attributes('src')).toBe(approval.user.avatarUrl);
    });

    it(`should show who ${status} the deployment`, () => {
      const link = wrapper.findByRole('link', { name: `@${approval.user.username}` });

      expect(link.attributes('href')).toBe(approval.user.webUrl);
    });

    it(`should show when they ${status} the deployment`, () => {
      const time = wrapper.find('time');

      expect(time.text()).toBe('just now');
    });

    it(`should show that the deployment has been ${status}`, () => {
      const statusText = wrapper.findByText(text);

      expect(statusText.exists()).toBe(true);
    });

    it('should show the comment associated with the approval', () => {
      const comment = wrapper.find('blockquote');

      expect(comment.text()).toBe(approval.comment);
    });
  });
});
