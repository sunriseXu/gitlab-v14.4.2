---
stage: Manage
group: Workspace
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Namespaces

In GitLab, a *namespace* provides one place to organize your related projects. Projects in one namespace are separate from projects in other namespaces,
which means you can use the same name for projects in different namespaces.

GitLab has two types of namespaces:

- A *Personal* namespace, which is based on your username and provided to you when you create your account.
  - If you change your username, the project and namespace URLs in your account also change. Before you change your username,
    read about [repository redirects](../project/repository/index.md#what-happens-when-a-repository-path-changes).
  - You cannot create subgroups in a personal namespace.
  - Groups in your namespace do not inherit your namespace permissions and group features.
  - All the *Personal Projects* created will fall under the scope of this namespace.

- A *group* or *subgroup* namespace:
  - You can create multiple subgroups to manage multiple projects.
  - You can change the URL of group and subgroup namespaces.
  - You can configure settings specifically for each subgroup and project in the namespace.
  - When you create a subgroup, it inherits some of the parent group settings. You can view these in the subgroup **Settings**.

To determine whether you're viewing a group or personal namespace, you can view the URL. For example:

| Namespace for | URL | Namespace |
| ------------- | --- | --------- |
| A user named `alex`. | `https://gitlab.example.com/alex` | `alex` |
| A group named `alex-team`. | `https://gitlab.example.com/alex-team` | `alex-team` |
| A group named `alex-team` with a subgroup named `marketing`. |  `https://gitlab.example.com/alex-team/marketing` | `alex-team/marketing` |
