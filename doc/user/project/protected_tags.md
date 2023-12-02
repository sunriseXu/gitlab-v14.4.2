---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Protected tags **(FREE)**

Protected tags:

- Allow control over who has permission to create tags.
- Prevent accidental update or deletion once created.

Each rule allows you to match either:

- An individual tag name.
- Wildcards to control multiple tags at once.

This feature evolved out of [protected branches](protected_branches.md)

## Who can modify a protected tag

By default:

- To create tags, you must have the Maintainer role.
- No one can update or delete tags.

## Configuring protected tags

To protect a tag, you must have at least the Maintainer role.

1. Go to the project's **Settings > Repository**.

1. From the **Tag** dropdown list, select the tag you want to protect or type and select **Create wildcard**. In the screenshot below, we chose to protect all tags matching `v*`:

   ![Protected tags page](img/protected_tags_page_v12_3.png)

1. From the **Allowed to create** dropdown list, select users with permission to create
   matching tags, and select **Protect**:

   ![Allowed to create tags dropdown list](img/protected_tags_permissions_dropdown_v12_3.png)

1. After done, the protected tag displays in the **Protected tags** list:

   ![Protected tags list](img/protected_tags_list_v12_3.png)

## Wildcard protected tags

You can specify a wildcard protected tag, which protects all tags
matching the wildcard. For example:

| Wildcard Protected Tag | Matching Tags                 |
|------------------------|-------------------------------|
| `v*`                   | `v1.0.0`, `version-9.1`       |
| `*-deploy`             | `march-deploy`, `1.0-deploy`  |
| `*gitlab*`             | `gitlab`, `gitlab/v1`         |
| `*`                    | `v1.0.1rc2`, `accidental-tag` |

Two different wildcards can potentially match the same tag. For example,
`*-stable` and `production-*` would both match a `production-stable` tag.
In that case, if _any_ of these protected tags have a setting like
**Allowed to create**, then `production-stable` also inherit this setting.

If you select a protected tag's name, GitLab displays a list of
all matching tags:

![Protected tag matches](img/protected_tag_matches.png)

## Prevent tag creation with the same name as branches

A tag and a branch with identical names can contain different commits. If your
tags and branches use the same names, users running `git checkout`
commands might check out the _tag_ `qa` when they instead meant to check out
the _branch_ `qa`.

To prevent this problem:

1. Identify the branch names you do not want used as tags.
1. As described in [Configuring protected tags](#configuring-protected-tags),
   create a protected tag:

   - For the **Name**, provide a name, such as `stable`. You can also create a wildcard
     like `stable-*` to match multiple names, like `stable-v1` and `stable-v2`.
   - For **Allowed to Create**, select **No one**.
   - Select **Protect**.

Users can still create branches, but not tags, with the protected names.

## Delete a protected tag

You can manually delete protected tags with the GitLab API, or the
GitLab user interface.

Prerequisite:

- You must have at least the Maintainer role in your project.

To do this:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Tags**.
1. Next to the tag you want to delete, select **Delete** (**{remove}**).
1. On the confirmation dialog, enter the tag name and select **Yes, delete protected tag**.

Protected tags can only be deleted by using GitLab either from the UI or API.
These protections prevent you from accidentally deleting a tag through local
Git commands or third-party Git clients.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
