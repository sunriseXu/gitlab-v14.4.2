import axios from 'axios';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '../../lib/utils/common_utils';
import { getIdFromGraphQLId } from '../../graphql_shared/utils';
import {
  GRAPHQL_GROUP_TYPE,
  GRAPHQL_PROJECT_TYPE,
  groupString,
  instanceString,
  projectString,
} from '../constants';
import getProjectVariables from './queries/project_variables.query.graphql';
import getGroupVariables from './queries/group_variables.query.graphql';
import getAdminVariables from './queries/variables.query.graphql';

const prepareVariableForApi = ({ variable, destroy = false }) => {
  return {
    ...convertObjectPropsToSnakeCase(variable),
    id: getIdFromGraphQLId(variable?.id),
    variable_type: variable.variableType.toLowerCase(),
    secret_value: variable.value,
    _destroy: destroy,
  };
};

const mapVariableTypes = (variables = [], kind) => {
  return variables.map((ciVar) => {
    return {
      __typename: `Ci${kind}Variable`,
      ...convertObjectPropsToCamelCase(ciVar),
      variableType: ciVar.variable_type ? ciVar.variable_type.toUpperCase() : ciVar.variableType,
    };
  });
};

const prepareProjectGraphQLResponse = ({ data, projectId, errors = [] }) => {
  return {
    errors,
    project: {
      __typename: GRAPHQL_PROJECT_TYPE,
      id: projectId,
      ciVariables: {
        __typename: 'CiVariableConnection',
        nodes: mapVariableTypes(data.variables, projectString),
      },
    },
  };
};

const prepareGroupGraphQLResponse = ({ data, groupId, errors = [] }) => {
  return {
    errors,
    group: {
      __typename: GRAPHQL_GROUP_TYPE,
      id: groupId,
      ciVariables: {
        __typename: 'CiVariableConnection',
        nodes: mapVariableTypes(data.variables, groupString),
      },
    },
  };
};

const prepareAdminGraphQLResponse = ({ data, errors = [] }) => {
  return {
    errors,
    ciVariables: {
      __typename: `Ci${instanceString}VariableConnection`,
      nodes: mapVariableTypes(data.variables, instanceString),
    },
  };
};

const callProjectEndpoint = async ({
  endpoint,
  fullPath,
  variable,
  projectId,
  cache,
  destroy = false,
}) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });
    return prepareProjectGraphQLResponse({ data, projectId });
  } catch (e) {
    return prepareProjectGraphQLResponse({
      data: cache.readQuery({ query: getProjectVariables, variables: { fullPath } }),
      projectId,
      errors: [...e.response.data],
    });
  }
};

const callGroupEndpoint = async ({
  endpoint,
  fullPath,
  variable,
  groupId,
  cache,
  destroy = false,
}) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });
    return prepareGroupGraphQLResponse({ data, groupId });
  } catch (e) {
    return prepareGroupGraphQLResponse({
      data: cache.readQuery({ query: getGroupVariables, variables: { fullPath } }),
      groupId,
      errors: [...e.response.data],
    });
  }
};

const callAdminEndpoint = async ({ endpoint, variable, cache, destroy = false }) => {
  try {
    const { data } = await axios.patch(endpoint, {
      variables_attributes: [prepareVariableForApi({ variable, destroy })],
    });

    return prepareAdminGraphQLResponse({ data });
  } catch (e) {
    return prepareAdminGraphQLResponse({
      data: cache.readQuery({ query: getAdminVariables }),
      errors: [...e.response.data],
    });
  }
};

export const resolvers = {
  Mutation: {
    addProjectVariable: async (_, { endpoint, fullPath, variable, projectId }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, projectId, cache });
    },
    updateProjectVariable: async (_, { endpoint, fullPath, variable, projectId }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, projectId, cache });
    },
    deleteProjectVariable: async (_, { endpoint, fullPath, variable, projectId }, { cache }) => {
      return callProjectEndpoint({ endpoint, fullPath, variable, projectId, cache, destroy: true });
    },
    addGroupVariable: async (_, { endpoint, fullPath, variable, groupId }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, groupId, cache });
    },
    updateGroupVariable: async (_, { endpoint, fullPath, variable, groupId }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, groupId, cache });
    },
    deleteGroupVariable: async (_, { endpoint, fullPath, variable, groupId }, { cache }) => {
      return callGroupEndpoint({ endpoint, fullPath, variable, groupId, cache, destroy: true });
    },
    addAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache });
    },
    updateAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache });
    },
    deleteAdminVariable: async (_, { endpoint, variable }, { cache }) => {
      return callAdminEndpoint({ endpoint, variable, cache, destroy: true });
    },
  },
};
