---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Description templates **(FREE)**

You can define templates to use as descriptions
for your [issues](issues/index.md) and [merge requests](merge_requests/index.md).

You can define these templates in a project, group, or instance. Projects
inherit the templates defined at a higher level.

You might want to use these templates:

- For different stages of your workflow, for example, feature proposal, feature improvement, or a bug report.
- For every issue or merge request for a specific project, so the layout is consistent.
- For a [Service Desk email template](service_desk.md#new-service-desk-issues).

For description templates to work, they must be:

- Saved with the `.md` extension.
- Stored in your project's repository in the `.gitlab/issue_templates`
  or `.gitlab/merge_request_templates` directory.
- Be present on the default branch.

## Create an issue template

Create a new Markdown (`.md`) file inside the `.gitlab/issue_templates/`
directory in your repository.

To create an issue description template:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository**.
1. Next to the default branch, select **{plus}**.
1. Select **New file**.
1. Next to the default branch, in the **File name** text box, enter `.gitlab/issue_templates/mytemplate.md`,
   where `mytemplate` is the name of your issue template.
1. Commit to your default branch.

To check if this has worked correctly, [create a new issue](issues/managing_issues.md#create-an-issue)
and see if you can find your description template in the **Choose a template** dropdown list.

## Create a merge request template

Similarly to issue templates, create a new Markdown (`.md`) file inside the
`.gitlab/merge_request_templates/` directory in your repository. Commit and
push to your default branch.

To create a merge request description template:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository**.
1. Next to the default branch, select **{plus}**.
1. Select **New file**.
1. Next to the default branch, in the **File name** text box, enter `.gitlab/merge_request_templates/mytemplate.md`,
   where `mytemplate` is the name of your merge request template.
1. Commit to your default branch.

To check if this has worked correctly, [create a new merge request](merge_requests/creating_merge_requests.md)
and see if you can find your description template in the **Choose a template** dropdown list.

## Use the templates

When you create or edit an issue or a merge request, it shows in the **Choose a template** dropdown list.

To apply a template:

1. Create or edit an issue or a merge request.
1. Select the **Choose a template** dropdown list.
1. If the **Description** text box hasn't been empty, to confirm, select **Apply template**.
1. Select **Save changes**.

When you select a description template, its content is copied to the description text box.

To discard any changes to the description you've made after selecting the template: expand the **Choose a template** dropdown list and select **Reset template**.

![Choosing a description template in an issue](img/description_templates_v14_7.png)

NOTE:
You can create shortcut links to create an issue using a designated template.
For example: `https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal`. Read more about [creating issues using a URL with prefilled values](issues/managing_issues.md#using-a-url-with-prefilled-values).

### Set instance-level description templates **(PREMIUM SELF)**

You can set a description template at the **instance level** for issues
and merge requests by using an [instance template repository](../admin_area/settings/instance_template_repository.md).
You can also use the instance template repository for file templates.

You might also be interested [project templates](../admin_area/custom_project_templates.md)
that you can use when creating a new project in the instance.

### Set group-level description templates **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52360) in GitLab 13.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/321247) in GitLab 14.0.

With **group-level** description templates, you can store your templates in a single repository and
configure the group file templates setting to point to that repository.
As a result, you can use the same templates in issues and merge requests in all the group's projects.

To re-use templates [you've created](../project/description_templates.md#create-an-issue-template):

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Templates**.
1. From the dropdown list, select your template project as the template repository at group level.
1. Select **Save changes**.

![Group template settings](../group/img/group_file_template_settings.png)

You might also be interested in templates for various
[file types in groups](../group/manage.md#group-file-templates).

### Set a default template for merge requests and issues

> `Default.md` (case insensitive) template [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78302) in GitLab 14.8.

In a project, you can choose a default description template for new issues and merge requests.
As a result, every time a new merge request or issue is created, it's pre-filled with the text you
entered in the template.

Prerequisites:

- On your project's left sidebar, select **Settings > General** and expand **Visibility, project features, permissions**.
  Ensure issues or merge requests are set to either **Everyone with access** or **Only Project Members**.

To set a default description template for merge requests, either:

- [In GitLab 14.8 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78302), [create a merge request template](#create-a-merge-request-template) named `Default.md` (case insensitive)
  and save it in `.gitlab/merge_request_templates/`.
  This [doesn't overwrite](#priority-of-default-description-templates) the default template if one has been set in the project settings.
- Users on GitLab Premium and higher: set the default template in project settings:

  1. On the top bar, select **Main menu > Projects** and find your project.
  1. On the left sidebar, select **Settings > Merge requests**.
  1. In the **Merge commit message template** section, fill in **Default description template for merge requests**.
  1. Select **Save changes**.

To set a default description template for issues, either:

- [In GitLab 14.8 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78302), [create an issue template](#create-an-issue-template) named `Default.md` (case insensitive)
  and save it in `.gitlab/issue_templates/`.
  This [doesn't overwrite](#priority-of-default-description-templates) the default template if one has been set in the project settings.
- Users on GitLab Premium and higher: set the default template in project settings:

  1. On the top bar, select **Main menu > Projects** and find your project.
  1. On the left sidebar, select **Settings**.
  1. Expand **Default issue template**.
  1. Fill in the **Default description template for issues** text area.
  1. Select **Save changes**.

Because GitLab merge request and issues support [Markdown](../markdown.md), you can use it to format
headings, lists, and so on.

You can also provide `issues_template` and `merge_requests_template` attributes in the
[Projects REST API](../../api/projects.md) to keep your default issue and merge request templates up to date.

#### Priority of default description templates

When you set [merge request and issue description templates](#set-a-default-template-for-merge-requests-and-issues)
in various places, they have the following priorities in a project.
The ones higher up override the ones below:

1. Template set in project settings.
1. `Default.md` (case insensitive) from the parent group.
1. `Default.md` (case insensitive) from the project repository.

## Example description template

We use description templates for issues and merge requests in the
[`.gitlab` folder](https://gitlab.com/gitlab-org/gitlab/-/tree/master/.gitlab) of the
GitLab project, which you can refer to for some examples.

NOTE:
It's possible to use [quick actions](quick_actions.md) in description templates to quickly add
labels, assignees, and milestones. The quick actions are only executed if the user submitting
the issue or merge request has the permissions to perform the relevant actions.

Here is an example of a bug report template:

```markdown
## Summary

(Summarize the bug encountered concisely)

## Steps to reproduce

(How one can reproduce the issue - this is very important)

## Example Project

(If possible, please create an example project here on GitLab.com that exhibits the problematic
behavior, and link to it here in the bug report.
If you are using an older version of GitLab, this will also determine whether the bug has been fixed
in a more recent version)

## What is the current bug behavior?

(What actually happens)

## What is the expected correct behavior?

(What you should see instead)

## Relevant logs and/or screenshots

(Paste any relevant logs - please use code blocks (```) to format console output, logs, and code, as
it's very hard to read otherwise.)

## Possible fixes

(If you can, link to the line of code that might be responsible for the problem)

/label ~bug ~reproduced ~needs-investigation
/cc @project-manager
/assign @qa-tester
```
