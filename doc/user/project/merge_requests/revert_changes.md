---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Revert changes **(FREE)**

You can revert individual commits or an entire merge request in GitLab.
When you revert a commit in Git, you create a new commit that reverses all actions
taken in the original commit:

- Lines added in the original commit are removed.
- Lines removed in the original commit are added back.
- Lines modified in the original commit are restored to their previous state.

Your **revert commit** is still subject to your project's access controls and processes.

## Revert a merge request

After a merge request is merged, you can revert all changes in the merge request.

Prerequisites:

- You must have a role in the project that allows you to edit merge requests, and add
  code to the repository.
- Your project must use the [merge method](methods/index.md#fast-forward-merge) **Merge Commit**,
  which is set in the project's **Settings > General > Merge request**. You can't revert
  fast-forwarded commits from the GitLab UI.

To do this:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Merge requests** and identify your merge request.
1. Scroll to the merge request reports area, and find the report showing when the
   merge request was merged.
1. Select **Revert**.
1. In **Revert in branch**, select the branch to revert your changes into.
1. Optional. Select **Start a new merge request** to start a new merge request with the new revert commit.
1. Select **Revert**.

The option to **Revert** is no longer shown after a merge request is reverted.

## Revert a commit

You can revert any commit in a repository into either:

- The current branch.
- A new merge request.

Prerequisites:

- You must have a role in the project that allows you to edit merge requests, and add
  code to the repository.

To do this:

1. On the top bar, select **Main menu > Projects** and find your project.
1. If you know the merge request that contains the commit:
   1. On the left sidebar, select **Merge requests** and identify your merge request.
   1. Select **Commits**, then select the title of the commit you want to revert. GitLab displays the contents of the commit.
1. If you don't know the merge request the commit originated from:
   1. On the left sidebar, select **Repository > Commits**.
   1. Select the title of the commit to display full information about the commit.
1. In the top right corner, select **Options**, then select **Revert**.
1. In **Revert in branch**, select the branch to revert your changes into.
1. Optional. Select **Start a new merge request** to start a new merge request with the new revert commit.
1. Select **Revert**.

The option to **Revert** is no longer shown after a commit is reverted.

### Revert a merge commit to a different parent commit

When you revert a merge commit, the branch you merged to (usually `main`) is always the
first parent. To revert a merge commit to a different parent,
you must revert the commit from the command line:

1. Identify the SHA of the parent commit you want to revert to.
1. Identify the parent number of the commit you want to revert to. (Defaults to 1, for the first parent.)
1. Modify this command, replacing `2` with the parent number, and `7a39eb0` with the commit SHA:

   ```shell
   git revert -m 2 7a39eb0
   ```

## Related topics

- [Official `git revert` documentation](https://git-scm.com/docs/git-revert)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
