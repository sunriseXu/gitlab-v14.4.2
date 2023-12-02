---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Linked resources in incidents **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230852) in GitLab 15.3 [with a flag](../../administration/feature_flags.md) named `incident_resource_links_widget`. Enabled on GitLab.com. Disabled on self-managed.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `incident_resource_links_widget`.
On GitLab.com, this feature is available.

To help your team members find the important links without having to search through many comments,
you can add linked resources to an incident issue.

Resources you might want link to:

- Zoom meetings
- Slack channels or threads
- Google Docs

## View linked resources of an incident

Linked resources for an incident are listed under the **Summary** tab.

![Linked resources list](img/linked_resources_list_v15_3.png)

To view the linked resources of an incident:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.

## Add a linked resource

Add a linked resource manually from an incident.

Prerequisites:

- You must have at least the Reporter role for the project.

To add a linked resource:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.
1. In the **Linked resources** section, select the plus icon (**{plus-square}**).
1. Complete the required fields.
1. Select **Add**.

### Link Zoom meetings from an incident **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230853) in GitLab 15.4.

Use the `/zoom` [quick action](../../user/project/quick_actions.md) to add multiple Zoom links to an incident:

```plaintext
/zoom https://example.zoom.us/j/123456789
```

You can also submit a short optional description with the link. The description shows instead of the URL in the **Linked resources** section of the incident issue:

```plaintext
/zoom https://example.zoom.us/j/123456789, Low on memory incident
```

## Remove a linked resource

You can also remove a linked resource.

Prerequisites:

- You must have at least the Reporter role for the project.

To remove a linked resource:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.
1. In the **Linked resources** section, select **Remove** (**{close}**).
