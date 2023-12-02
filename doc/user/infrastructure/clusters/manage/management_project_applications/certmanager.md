---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install cert-manager with a cluster management project **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.
> - Support for cert-manager v1.4 was [introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/69405) in GitLab 14.3.
> - [Upgraded](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/23) to cert-manager 1.7 in GitLab 14.8.

Assuming you already have a project created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install cert-manager you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/cert-manager/helmfile.yaml
```

And update the `applications/cert-manager/helmfile.yaml` with a valid email address.

```yaml
  values:
    - letsEncryptClusterIssuer:
        #
        # IMPORTANT: This value MUST be set to a valid email.
        #
        email: example@example.com
```

NOTE:
If your Kubernetes version is earlier than 1.20 and you are
[migrating from GitLab Managed Apps to a cluster management project](../../../../clusters/migrating_from_gma_to_project_template.md),
then you can instead use `- path: applications/cert-manager-legacy/helmfile.yaml` to
take over an existing release of cert-manager v0.10.

cert-manager:

- Is installed by default into the `gitlab-managed-apps` namespace of your cluster.
- Includes a
  [Let's Encrypt `ClusterIssuer`](https://cert-manager.io/docs/configuration/acme/) enabled by
  default. In the `certmanager-issuer` release, the issuer requires a valid email address
  for `letsEncryptClusterIssuer.email`. Let's Encrypt uses this email address to
  contact you about expiring certificates and issues related to your account.
- Can be customized in `applications/cert-manager/helmfile.yaml` by passing custom
  `values` to the `certmanager` release. Refer to the
  [chart](https://github.com/jetstack/cert-manager) for the available
  configuration options.
