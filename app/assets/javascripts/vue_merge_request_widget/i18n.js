import { __, s__ } from '~/locale';

export const MR_WIDGET_MISSING_BRANCH_WHICH = s__(
  'mrWidget|The %{type} branch %{codeStart}%{name}%{codeEnd} does not exist.',
);
export const MR_WIDGET_MISSING_BRANCH_RESTORE = s__(
  'mrWidget|Please restore it or use a different %{type} branch.',
);
export const MR_WIDGET_MISSING_BRANCH_MANUALCLI = s__(
  'mrWidget|If the %{type} branch exists in your local repository, you can merge this merge request manually using the command line.',
);

export const SQUASH_BEFORE_MERGE = {
  tooltipTitle: __('Required in this project.'),
  checkboxLabel: __('Squash commits'),
  helpLabel: __('What is squashing?'),
};

export const I18N_SHA_MISMATCH = {
  warningMessage: __('Merge blocked: new changes were just added.'),
  actionButtonLabel: __('Review changes'),
};

export const MERGE_TRAIN_BUTTON_TEXT = {
  failed: __('Start merge train...'),
  passed: __('Start merge train'),
};
