import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerStackedSummaryCell from '~/runner/components/cells/runner_stacked_summary_cell.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RunnerTags from '~/runner/components/runner_tags.vue';
import RunnerSummaryField from '~/runner/components/cells/runner_summary_field.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import { INSTANCE_TYPE, I18N_INSTANCE_TYPE, PROJECT_TYPE } from '~/runner/constants';

import { allRunnersData } from '../../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

describe('RunnerTypeCell', () => {
  let wrapper;

  const findLockIcon = () => wrapper.findByTestId('lock-icon');
  const findRunnerTags = () => wrapper.findComponent(RunnerTags);
  const findRunnerSummaryField = (icon) =>
    wrapper.findAllComponents(RunnerSummaryField).filter((w) => w.props('icon') === icon)
      .wrappers[0];

  const createComponent = (runner, options) => {
    wrapper = mountExtended(RunnerStackedSummaryCell, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        RunnerSummaryField,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays the runner name as id and short token', () => {
    expect(wrapper.text()).toContain(
      `#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha})`,
    );
  });

  it('Does not display the locked icon', () => {
    expect(findLockIcon().exists()).toBe(false);
  });

  it('Displays the locked icon for locked runners', () => {
    createComponent({
      runnerType: PROJECT_TYPE,
      locked: true,
    });

    expect(findLockIcon().exists()).toBe(true);
  });

  it('Displays the runner type', () => {
    createComponent({
      runnerType: INSTANCE_TYPE,
      locked: true,
    });

    expect(wrapper.text()).toContain(I18N_INSTANCE_TYPE);
  });

  it('Displays the runner version', () => {
    expect(wrapper.text()).toContain(mockRunner.version);
  });

  it('Displays the runner description', () => {
    expect(wrapper.text()).toContain(mockRunner.description);
  });

  it('Displays last contact', () => {
    createComponent({
      contactedAt: '2022-01-02',
    });

    expect(findRunnerSummaryField('clock').find(TimeAgo).props('time')).toBe('2022-01-02');
  });

  it('Displays empty last contact', () => {
    createComponent({
      contactedAt: null,
    });

    expect(findRunnerSummaryField('clock').find(TimeAgo).exists()).toBe(false);
    expect(findRunnerSummaryField('clock').text()).toContain(__('Never'));
  });

  it('Displays ip address', () => {
    createComponent({
      ipAddress: '127.0.0.1',
    });

    expect(findRunnerSummaryField('disk').text()).toContain('127.0.0.1');
  });

  it('Displays no ip address', () => {
    createComponent({
      ipAddress: null,
    });

    expect(findRunnerSummaryField('disk')).toBeUndefined();
  });

  it('Displays job count', () => {
    expect(findRunnerSummaryField('pipeline').text()).toContain(`${mockRunner.jobCount}`);
  });

  it('Formats large job counts', () => {
    createComponent({
      jobCount: 1000,
    });

    expect(findRunnerSummaryField('pipeline').text()).toContain('1,000');
  });

  it('Formats large job counts with a plus symbol', () => {
    createComponent({
      jobCount: 1001,
    });

    expect(findRunnerSummaryField('pipeline').text()).toContain('1,000+');
  });

  it('Displays created at', () => {
    expect(findRunnerSummaryField('calendar').find(TimeAgo).props('time')).toBe(
      mockRunner.createdAt,
    );
  });

  it('Displays tag list', () => {
    createComponent({
      tagList: ['shell', 'linux'],
    });

    expect(findRunnerTags().props('tagList')).toEqual(['shell', 'linux']);
  });

  it('Displays a custom slot', () => {
    const slotContent = 'My custom runner name';

    createComponent(
      {},
      {
        slots: {
          'runner-name': slotContent,
        },
      },
    );

    expect(wrapper.text()).toContain(slotContent);
  });
});
