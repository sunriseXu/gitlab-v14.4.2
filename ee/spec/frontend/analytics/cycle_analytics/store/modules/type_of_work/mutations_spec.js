import { TASKS_BY_TYPE_FILTERS } from 'ee/analytics/cycle_analytics/constants';
import * as types from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutations';

import {
  apiTasksByTypeData,
  rawTasksByTypeData,
  groupLabels,
  groupLabelNames,
  groupLabelIds,
} from '../../../mock_data';

let state = null;

describe('Value Stream Analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                         | stateKey                       | value
    ${types.REQUEST_TOP_RANKED_GROUP_LABELS}         | ${'topRankedLabels'}           | ${[]}
    ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR}   | ${'topRankedLabels'}           | ${[]}
    ${types.REQUEST_TOP_RANKED_GROUP_LABELS}         | ${'selectedLabelNames'}        | ${[]}
    ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR}   | ${'selectedLabelNames'}        | ${[]}
    ${types.REQUEST_TOP_RANKED_GROUP_LABELS}         | ${'errorCode'}                 | ${null}
    ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS} | ${'errorCode'}                 | ${null}
    ${types.REQUEST_TOP_RANKED_GROUP_LABELS}         | ${'errorMessage'}              | ${''}
    ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS} | ${'errorMessage'}              | ${''}
    ${types.REQUEST_TASKS_BY_TYPE_DATA}              | ${'isLoadingTasksByTypeChart'} | ${true}
    ${types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR}        | ${'isLoadingTasksByTypeChart'} | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation             | payload | expectedState
    ${types.SET_LOADING} | ${true} | ${{ isLoadingTasksByTypeChart: true, isLoadingTasksByTypeChartTopLabels: true }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {};
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS}`, () => {
    it('sets selectedLabelIds to an array of label ids', () => {
      mutations[types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS](state, groupLabels);

      expect(state.selectedLabelIds).toEqual(groupLabelIds);
    });

    it('sets selectedLabelNames to an array of label ids', () => {
      mutations[types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS](state, groupLabels);

      expect(state.selectedLabelNames).toEqual(groupLabelNames);
    });
  });

  describe(`${types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS}`, () => {
    it('sets isLoadingTasksByTypeChart to false', () => {
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, {});

      expect(state.isLoadingTasksByTypeChart).toEqual(false);
    });

    it('sets data to the raw returned chart data', () => {
      state = { data: null };
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, apiTasksByTypeData);

      expect(state.data).toEqual(rawTasksByTypeData);
    });
  });

  describe(`${types.SET_TASKS_BY_TYPE_FILTERS}`, () => {
    it('will update the tasksByType state key', () => {
      state = {};
      const subjectFilter = { filter: TASKS_BY_TYPE_FILTERS.SUBJECT, value: 'cool-subject' };
      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, subjectFilter);

      expect(state.subject).toEqual('cool-subject');
    });

    it('will toggle the specified label id in the selectedLabelIds state key', () => {
      state = {
        selectedLabelIds: [10, 20, 30],
      };
      const labelFilter = { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: { id: 20 } };
      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);

      expect(state.selectedLabelIds).toEqual([10, 30]);

      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);
      expect(state.selectedLabelIds).toEqual([10, 30, 20]);
    });

    it('will toggle the specified label title in the selectedLabelNames state key', () => {
      state = {
        selectedLabelNames: ['label 1', 'label 2', 'label 3'],
      };
      const labelFilter = { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: { title: 'label 2' } };
      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);

      expect(state.selectedLabelNames).toEqual(['label 1', 'label 3']);

      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);
      expect(state.selectedLabelNames).toEqual(['label 1', 'label 3', 'label 2']);
    });
  });
});
