---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Export merge requests to CSV **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3619) in GitLab 13.6.

Export all the data collected from a project's merge requests into a comma-separated values (CSV) file.

To export merge requests to a CSV file:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Merge requests** .
1. Add any searches or filters. This can help you keep the size of the CSV file under the 15MB limit. The limit ensures
   the file can be emailed to a variety of email providers.
1. Select **Export as CSV** (**{export}**).
1. Confirm the correct number of merge requests are to be exported.
1. Select **Export merge requests**.

## CSV Output

The following table shows the attributes in the CSV file.

| Column             | Description                                                  |
|--------------------|--------------------------------------------------------------|
| Title              | Merge request title                                          |
| Description        | Merge request description                                    |
| MR ID              | MR `iid`                                                     |
| URL                | A link to the merge request on GitLab                        |
| State              | Opened, Closed, Locked, or Merged                            |
| Source Branch      | Source branch                                                |
| Target Branch      | Target branch                                                |
| Source Project ID  | ID of the source project                                     |
| Target Project ID  | ID of the target project                                     |
| Author             | Full name of the merge request author                        |
| Author Username    | Username of the author, with the @ symbol omitted            |
| Assignees          | Full names of the merge request assignees, joined with a `,` |
| Assignee Usernames | Username of the assignees, with the @ symbol omitted         |
| Approvers          | Full names of the approvers, joined with a `,`               |
| Approver Usernames | Username of the approvers, with the @ symbol omitted         |
| Merged User        | Full name of the merged user                                 |
| Merged Username    | Username of the merge user, with the @ symbol omitted        |
| Milestone ID       | ID of the merge request milestone                            |
| Created At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS`                           |
| Updated At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS`                           |

In GitLab 14.7 and earlier, the first two columns were `MR ID` and `URL`,
which [caused an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/34769)
when importing back into GitLab.
