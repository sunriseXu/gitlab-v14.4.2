---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Import a project from GitLab.com to your private GitLab instance **(FREE)**

You can import your existing GitLab.com projects to your GitLab instance.

Prerequisite:

- GitLab.com integration must be enabled on your GitLab instance.
  [Read more about GitLab.com integration for self-managed GitLab instances](../../../integration/gitlab.md).

To import a GitLab.com project to your self-managed GitLab instance:

1. In GitLab, on the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Import project**.
1. Select **GitLab.com**.
1. Give GitLab.com permission to access your projects.
1. Select **Import**.

The importer imports your repository and issues.
When the importer is done, a new GitLab project is created with your imported data.

## Related topics

- To automate user, group, and project import API calls, see
  [Automate group and project import](index.md#automate-group-and-project-import).
- To import Wiki and merge request data to your new instance,
  see [exporting a project](../settings/import_export.md#export-a-project-and-its-data).
