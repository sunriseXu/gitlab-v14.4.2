---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pipeline status emails **(FREE)**

You can send notifications about pipeline status changes in a group or
project to a list of email addresses.

## Enable pipeline status email notifications

To enable pipeline status emails:

1. In your project or group, on the left sidebar, select **Settings > Integrations**.
1. Select **Pipeline status emails**.
1. Ensure the **Active** checkbox is selected.
1. In **Recipients**, enter a comma-separated list of email addresses.
1. Optional. To receive notifications for broken pipelines only, select
   **Notify only broken pipelines**.
1. Select the branches to send notifications for.
1. Select **Save changes**.

In [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89546)
and later, pipeline notifications triggered by blocked users are not delivered.
