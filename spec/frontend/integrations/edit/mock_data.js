export const mockIntegrationProps = {
  id: 25,
  initialActivated: true,
  showActive: true,
  editable: true,
  triggerFieldsProps: {
    initialTriggerCommit: false,
    initialTriggerMergeRequest: false,
    initialEnableComments: false,
  },
  jiraIssuesProps: {},
  triggerEvents: [
    { name: 'push_events', title: 'Push', value: true },
    { name: 'issues_events', title: 'Issue', value: true },
  ],
  sections: [],
  fields: [],
  type: '',
  inheritFromId: 25,
  integrationLevel: 'project',
};

export const mockJiraIssueTypes = [
  { id: '1', name: 'issue', description: 'issue' },
  { id: '2', name: 'bug', description: 'bug' },
  { id: '3', name: 'epic', description: 'epic' },
];

export const mockField = {
  help: 'The URL of the project',
  name: 'project_url',
  placeholder: 'https://jira.example.com',
  title: 'Project URL',
  type: 'text',
  value: '1',
};

export const mockSectionConnection = {
  type: 'connection',
  title: 'Connection details',
  description: 'Learn more on how to configure this integration.',
};

export const mockSectionJiraIssues = {
  type: 'jira_issues',
  title: 'Issues',
  description:
    'Work on Jira issues without leaving GitLab. Add a Jira menu to access a read-only list of your Jira issues. Learn more.',
  plan: 'premium',
};
