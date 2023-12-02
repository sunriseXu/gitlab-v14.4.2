import { __ } from '~/locale';

export const ADD_CI_VARIABLE_MODAL_ID = 'add-ci-variable';

// This const will be deprecated once we remove VueX from the section
export const displayText = {
  variableText: __('Variable'),
  fileText: __('File'),
  allEnvironmentsText: __('All (default)'),
};

export const variableTypes = {
  envType: 'ENV_VAR',
  fileType: 'FILE',
};

// Once REST is removed, we won't need `types`
export const types = {
  variableType: 'env_var',
  fileType: 'file',
};

export const allEnvironments = {
  type: '*',
  text: __('All (default)'),
};

// Once REST is removed, we won't need `types` key
export const variableText = {
  [types.variableType]: __('Variable'),
  [types.fileType]: __('File'),
  [variableTypes.envType]: __('Variable'),
  [variableTypes.fileType]: __('File'),
};

export const variableOptions = [
  { value: variableTypes.envType, text: variableText[variableTypes.envType] },
  { value: variableTypes.fileType, text: variableText[variableTypes.fileType] },
];

export const defaultVariableState = {
  environmentScope: allEnvironments.type,
  key: '',
  masked: false,
  protected: false,
  value: '',
  variableType: variableTypes.envType,
};

// eslint-disable-next-line @gitlab/require-i18n-strings
export const groupString = 'Group';
// eslint-disable-next-line @gitlab/require-i18n-strings
export const instanceString = 'Instance';
// eslint-disable-next-line @gitlab/require-i18n-strings
export const projectString = 'Instance';

export const AWS_TIP_DISMISSED_COOKIE_NAME = 'ci_variable_list_constants_aws_tip_dismissed';
export const AWS_TIP_MESSAGE = __(
  '%{deployLinkStart}Use a template to deploy to ECS%{deployLinkEnd}, or use a docker image to %{commandsLinkStart}run AWS commands in GitLab CI/CD%{commandsLinkEnd}.',
);

export const EVENT_LABEL = 'ci_variable_modal';
export const EVENT_ACTION = 'validation_error';

// AWS TOKEN CONSTANTS
export const AWS_ACCESS_KEY_ID = 'AWS_ACCESS_KEY_ID';
export const AWS_DEFAULT_REGION = 'AWS_DEFAULT_REGION';
export const AWS_SECRET_ACCESS_KEY = 'AWS_SECRET_ACCESS_KEY';
export const AWS_TOKEN_CONSTANTS = [AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY];

export const CONTAINS_VARIABLE_REFERENCE_MESSAGE = __(
  'Values that contain the %{codeStart}$%{codeEnd} character can be considered a variable reference and expanded. %{docsLinkStart}Learn more.%{docsLinkEnd}',
);

export const ENVIRONMENT_SCOPE_LINK_TITLE = __('Learn more');

export const ADD_VARIABLE_ACTION = 'ADD_VARIABLE';
export const EDIT_VARIABLE_ACTION = 'EDIT_VARIABLE';
export const VARIABLE_ACTIONS = [ADD_VARIABLE_ACTION, EDIT_VARIABLE_ACTION];

export const GRAPHQL_PROJECT_TYPE = 'Project';
export const GRAPHQL_GROUP_TYPE = 'Group';

export const ADD_MUTATION_ACTION = 'add';
export const UPDATE_MUTATION_ACTION = 'update';
export const DELETE_MUTATION_ACTION = 'delete';

export const environmentFetchErrorText = __(
  'There was an error fetching the environments information.',
);
export const genericMutationErrorText = __('Something went wrong on our end. Please try again.');
export const variableFetchErrorText = __('There was an error fetching the variables.');
