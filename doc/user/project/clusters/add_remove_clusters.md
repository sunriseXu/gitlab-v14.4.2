---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Add a cluster using cluster certificates (DEPRECATED) **(FREE)**

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/327908) in GitLab 14.0.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/327908) in GitLab 14.0.
To create and manage a new cluster use [Infrastructure as Code](../../infrastructure/iac/index.md).

## Disable a cluster

When you successfully connect an existing cluster using cluster certificates, the cluster connection to GitLab becomes enabled. To disable it:

1. Go to your:
   - Project's **{cloud-gear}** **Infrastructure > Kubernetes clusters** page, for a project-level cluster.
   - Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   - **Main menu > Admin > Kubernetes** page, for an instance-level cluster.
1. Select the name of the cluster you want to disable.
1. Toggle **GitLab Integration** off (in gray).
1. Select **Save changes**.

## Remove a cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26815) in GitLab 12.6, you can remove cluster integrations and resources.

When you remove a cluster integration, you only remove the cluster relationship
to GitLab, not the cluster. To remove the cluster itself, visit your cluster's
GKE or EKS dashboard to do it from their UI or use `kubectl`.

You need at least Maintainer [permissions](../../permissions.md) to your
project or group to remove the integration with GitLab.

When removing a cluster integration, you have two options:

- **Remove integration**: remove only the Kubernetes integration.
- **Remove integration and resources**: remove the cluster integration and
all GitLab cluster-related resources such as namespaces, roles, and bindings.

To remove the Kubernetes cluster integration:

1. Go to your cluster details page.
1. Select the **Advanced Settings** tab.
1. Select either **Remove integration** or **Remove integration and resources**.

### Remove clusters by using the Rails console **(FREE SELF)**

[Start a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

To find a cluster:

``` ruby
cluster = Clusters::Cluster.find(1)
cluster = Clusters::Cluster.find_by(name: 'cluster_name')
```

To delete a cluster but not the associated resources:

```ruby
# Find users who have administrator access
user = User.find_by(username: 'admin_user')

# Find the cluster with the ID
cluster = Clusters::Cluster.find(1)

# Delete the cluster
Clusters::DestroyService.new(user).execute(cluster)
```
