import initStaleRunnerCleanupSetting from 'ee_else_ce/group_settings/stale_runner_cleanup';
import initVariableList from '~/ci_variable_list';
import initSharedRunnersForm from '~/group_settings/mount_shared_runners';
import initSettingsPanels from '~/settings_panels';

// Initialize expandable settings panels
initSettingsPanels();

initSharedRunnersForm();
initStaleRunnerCleanupSetting();
initVariableList();
