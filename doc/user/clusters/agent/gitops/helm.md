---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Using Helm charts to update a Kubernetes cluster (Alpha) **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371019) in GitLab 15.4.

You can deploy Helm charts to your Kubernetes cluster and keep the resources in your cluster in sync
with your charts and values. To do this, you use the pull-based GitOps features of the agent for
Kubernetes.

This feature is in Alpha and [an epic exists](https://gitlab.com/groups/gitlab-org/-/epics/7938)
to track future work. Please tell us about your use cases by leaving comments in the epic.

NOTE:
This feature is Alpha. In future releases, to accommodate new features, the configuration format might change without notice.

## GitOps workflow steps

To update a Kubernetes cluster by using GitOps with charts, complete the following steps.

1. Ensure you have a working Kubernetes cluster, and that the chart is in a GitLab project.
1. In the same project, [register and install the GitLab agent](../install/index.md).
1. Configure the agent configuration file so that the agent monitors the project for changes to the chart.
   Use the [GitOps configuration reference](#helm-configuration-reference) for guidance.

## Helm chart with GitOps workflow

To update a Kubernetes cluster by using Helm charts:

1. Ensure you have a working Kubernetes cluster.
1. In a GitLab project:
   - Store your Helm charts.
   - [Register and install the GitLab agent](../install/index.md).
1. Update the agent configuration file so that the agent monitors the project for changes to the chart.
   Use the [configuration reference](#helm-configuration-reference) for guidance.

Any time you commit updates to your chart repository, the agent applies the chart in the cluster.

## Helm configuration reference

The following snippet shows an example of the possible keys and values for the GitOps section of an [agent configuration file](../install/index.md#create-an-agent-configuration-file) (`config.yaml`).

```yaml
gitops:
  charts:
  - release_name: my-application-release
    source:
      project:
        id: my-group/my-project-with-chart
        path: dir-in-project/with/charts
    namespace: my-ns
    max_history: 1
```

| Keyword | Description |
|--|--|
| `charts` | List of charts you want to be applied in your cluster. Charts are applied concurrently. All charts must be in the same directory. |
| `release_name` | Required. Name of the release to use when applying the chart. |
| `id` | Required. ID of the project where Helm chart is committed. No authentication mechanisms are currently supported. |
| `path` | Optional. Path of the chart in the project repository. Root of the repository is used by default. This is the directory with the `Chart.yaml` file. |
| `namespace` | Optional. Namespace to use when applying the chart. Defaults to `default`. |
| `max_history` | Optional. Maximum number of release [revisions to store in the cluster](https://helm.sh/docs/helm/helm_history/). |

## Automatic drift remediation

Drift happens when the current configuration of an infrastructure resource differs from its desired configuration.
Typically, drift is caused by manually editing resources directly, rather than by editing the code that describes the desired state. Minimizing the risk of drift helps to ensure configuration consistency and successful operations.
mechanism. Minimizing the risk of drift helps to ensure configuration consistency and successful operations.

In GitLab, the agent for Kubernetes regularly compares the desired state from the chart source with
the actual state from the Kubernetes cluster. Deviations from the desired state are fixed at every check. These checks
happen automatically every 5 minutes. They are not configurable.

## Example repository layout

```plaintext
/my-chart
 ├── templates
 |   └── ...
 ├── charts
 |   └── ...
 ├── Chart.yaml
 ├── Chart.lock
 ├── values.yaml
 ├── values.schema.json
 └── some-file-used-in-chart.txt
```

## Known issues

The following are known issues:

- Your chart must be in a GitLab project. The project must be an agent configuration project or a public
  project. This known issue also exists for manifest-based GitOps and is tracked in
  [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7704).
- Values for the chart must be in a `values.yaml` file. This file must be with the chart,
  in the same project and path.
- Because of drift detection and remediation, release history, stored in the cluster, is not useful.
  A new release is created every five minutes and the oldest release is discarded.
  Eventually history consists only of the same information.
  View [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372023) for details.

## Troubleshooting

### Agent cannot find values for the chart

Make sure values are in `values.yaml` and in the same directory as the `Chart.yaml` file.
The filename must be lowercase, with `.yaml` extension (not `.yml`).
