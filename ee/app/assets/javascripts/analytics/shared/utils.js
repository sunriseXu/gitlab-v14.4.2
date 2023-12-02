import { dataVizBlue500, gray300 } from '@gitlab/ui/scss_to_js/scss_variables';
import { merge, cloneDeep } from 'lodash';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const formattedDate = (d) => dateFormat(d, dateFormats.defaultDate);

/**
 * Creates a value stream object from a dataset. Returns null if no valueStreamId is present.
 *
 * @param {Object} dataset - The raw value stream object
 * @returns {Object} - A value stream object
 */
export const buildValueStreamFromJson = (valueStream) => {
  const { id, name, is_custom: isCustom } = valueStream ? JSON.parse(valueStream) : {};
  return id ? { id, name, isCustom } : null;
};

/**
 * Creates an array of stage objects from a json string. Returns an empty array if no stages are present.
 *
 * @param {String} stages - JSON encoded array of stages
 * @returns {Array} - An array of stage objects
 */
const buildDefaultStagesFromJSON = (stages = '') => {
  if (!stages.length) return [];
  return JSON.parse(stages);
};

/**
 * Creates a group object from a dataset. Returns null if no groupId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A group object
 */
export const buildGroupFromDataset = (dataset) => {
  const { groupId, groupName, groupFullPath, groupAvatarUrl, groupParentId } = dataset;

  if (groupId) {
    return {
      id: Number(groupId),
      name: groupName,
      full_path: groupFullPath,
      avatar_url: groupAvatarUrl,
      parent_id: groupParentId,
    };
  }

  return null;
};

/**
 * Creates a project object from a dataset. Returns null if no projectId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A project object
 */
export const buildProjectFromDataset = (dataset) => {
  const { projectGid, projectName, projectPathWithNamespace, projectAvatarUrl } = dataset;

  if (projectGid) {
    return {
      id: projectGid,
      name: projectName,
      path_with_namespace: projectPathWithNamespace,
      avatar_url: projectAvatarUrl,
    };
  }

  return null;
};

/**
 * Creates a new date object without time zone conversion.
 *
 * We use this method instead of `new Date(date)`.
 * `new Date(date) will assume that the date string is UTC and it
 * ant return different date depending on the user's time zone.
 *
 * @param {String} date - Date string.
 * @returns {Date} - Date object.
 */
export const toLocalDate = (date) => {
  const dateParts = date.split('-');

  return new Date(dateParts[0], dateParts[1] - 1, dateParts[2]);
};

/**
 * Creates an array of project objects from a json string. Returns null if no projects are present.
 *
 * @param {String} data - JSON encoded array of projects
 * @returns {Array} - An array of project objects
 */
const buildProjectsFromJSON = (projects = '') => {
  if (!projects.length) return [];
  return JSON.parse(projects);
};

/**
 * Builds the initial data object for Value Stream Analytics with data loaded from the backend
 *
 * @param {Object} dataset - dataset object paseed to the frontend via data-* properties
 * @returns {Object} - The initial data to load the app with
 */
export const buildCycleAnalyticsInitialData = ({
  valueStream = null,
  groupId = null,
  createdBefore = null,
  createdAfter = null,
  projects = null,
  groupName = null,
  groupFullPath = null,
  groupParentId = null,
  groupAvatarUrl = null,
  labelsPath = '',
  milestonesPath = '',
  defaultStages = null,
  stage = null,
  aggregationEnabled = false,
  aggregationLastRunAt = null,
  aggregationNextRunAt = null,
} = {}) => ({
  selectedValueStream: buildValueStreamFromJson(valueStream),
  group: groupId
    ? convertObjectPropsToCamelCase(
        buildGroupFromDataset({
          groupId,
          groupName,
          groupFullPath,
          groupAvatarUrl,
          groupParentId,
        }),
      )
    : null,
  createdBefore: createdBefore ? toLocalDate(createdBefore) : null,
  createdAfter: createdAfter ? toLocalDate(createdAfter) : null,
  selectedProjects: projects
    ? buildProjectsFromJSON(projects).map(convertObjectPropsToCamelCase)
    : null,
  labelsPath,
  milestonesPath,
  defaultStageConfig: defaultStages
    ? buildDefaultStagesFromJSON(defaultStages).map(({ name, ...rest }) => ({
        ...convertObjectPropsToCamelCase(rest),
        name: capitalizeFirstCharacter(name),
      }))
    : [],
  stage: JSON.parse(stage),
  aggregation: {
    enabled: parseBoolean(aggregationEnabled),
    lastRunAt: aggregationLastRunAt,
    nextRunAt: aggregationNextRunAt,
  },
});

/**
 * Linearly interpolates between two values
 *
 * @param {Number} valueAtT0 The value at t = 0
 * @param {Number} valueAtT1 The value at t = 1
 * @param {Number} t The current value of t
 *
 * @returns {Number} The result of the linear interpolation.
 */
const lerp = (valueAtT0, valueAtT1, t) => {
  return valueAtT0 * (1 - t) + valueAtT1 * t;
};

/**
 * Builds a second series that visually represents the "no data" (i.e. "null")
 * data points, and returns a new series Array that includes both the "null"
 * and "non-null" data sets.
 * This function returns new series data and does not modify the original instance.
 *
 * @param {Array} seriesData The lead time series data that has already been processed
 * by the `apiDataToChartSeries` function above.
 * @returns {Array} A new series Array
 */
export const buildNullSeries = (seriesData, nullSeriesTitle) => {
  const nonNullSeries = cloneDeep(seriesData[0]);

  // Loop through the series data and build a list of all the "gaps". A "gap" is
  // a section of the data set that only include `null` values. Each gap object
  // includes the start and end indices and the start and end values of the gap.
  const seriesGaps = [];
  let currentGap = null;
  nonNullSeries.data.forEach(([, value], index) => {
    if (value == null && currentGap == null) {
      currentGap = {};

      if (index > 0) {
        currentGap.startIndex = index - 1;
        const [, previousValue] = nonNullSeries.data[index - 1];
        currentGap.startValue = previousValue;
      }

      seriesGaps.push(currentGap);
    } else if (value != null && currentGap != null) {
      currentGap.endIndex = index;
      currentGap.endValue = value;
      currentGap = null;
    }
  });

  // Create a copy of the non-null series, but with all the data point values set to `null`
  const nullSeriesData = nonNullSeries.data.map(([date]) => [date, null]);

  // Render each of the gaps to the "null" series. Values are determined by linearly
  // interpolating between the start and end values.
  seriesGaps.forEach((gap) => {
    const startIndex = gap.startIndex ?? 0;
    const startValue = gap.startValue ?? gap.endValue ?? 0;
    const endIndex = gap.endIndex ?? nonNullSeries.data.length - 1;
    const endValue = gap.endValue ?? gap.startValue ?? 0;

    for (let i = startIndex; i <= endIndex; i += 1) {
      const t = (i - startIndex) / (endIndex - startIndex);
      nullSeriesData[i][1] = lerp(startValue, endValue, t);
    }
  });

  merge(nonNullSeries, {
    showSymbol: true,
    showAllSymbol: true,
    symbolSize: 8,
    lineStyle: {
      color: dataVizBlue500,
    },
    areaStyle: {
      color: dataVizBlue500,
      opacity: 0,
    },
    itemStyle: {
      color: dataVizBlue500,
    },
  });

  const nullSeries = {
    name: nullSeriesTitle,
    data: nullSeriesData,
    lineStyle: {
      type: 'dashed',
      color: gray300,
    },
    areaStyle: {
      color: 'none',
    },
    itemStyle: {
      color: gray300,
    },
  };

  return [nullSeries, nonNullSeries];
};
