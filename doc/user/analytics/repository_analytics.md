---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Repository analytics for projects **(FREE)**

Use repository analytics to view information about a project's Git repository:

- Programming languages used in the repository.
- Code coverage history from last 3 months ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33743) in GitLab 13.1).
- Commit statistics (last month).
- Commits per day of month.
- Commits per weekday.
- Commits per day hour (UTC).

Repository analytics is part of [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss). It's available to anyone who has permission to clone the repository.

Repository analytics requires:

- An initialized Git repository.
- At least one commit in the default branch (`master` by default).

NOTE:
Without a Git commit in the default branch, the menu item isn't visible.
Commits in a project's [wiki](../project/wiki/index.md#track-wiki-events) are not included in the analysis.

## View repository analytics

To review repository analytics for a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Repository**.

## How repository analytics chart data is updated

Data in the charts are queued. Background workers update the charts 10 minutes after each commit in the default branch.
Depending on the size of the GitLab installation, it may take longer for data to refresh due to variations in the size of background job queues.
