---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API removed items **(FREE)**

GraphQL is a versionless API, unlike the REST API.
Occasionally, items have to be updated or removed from the GraphQL API.
According to our [process for removing items](index.md#deprecation-and-removal-process), here are the items that have been removed.

## GitLab 15.0

Fields removed in GitLab 15.0.

### GraphQL Mutations

[Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85382) in GitLab 15.0:

| Argument name        | Mutation                 | Deprecated in | Use instead                |
| -------------------- | --------------------     | ------------- | -------------------------- |
| -                    | `clusterAgentTokenDelete`| 14.7          | `clusterAgentTokenRevoke`  |

### GraphQL Fields

[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/342882) in GitLab 15.0:

| Argument name        | Field name          | Deprecated in | Use instead                |
| -------------------- | --------------------| ------------- | -------------------------- |
| -                    | `pipelines`         | 14.5          | None                       |

### GraphQL Types

| Field name                                 | GraphQL type             | Deprecated in | Use instead                                                                        |
| ------------------------------------------ | ------------------------ | ------------- | ---------------------------------------------------------------------------------- |
| `defaultMergeCommitMessageWithDescription` | `GraphQL::Types::String` | 14.5          | None. Define a [merge commit template](../../user/project/merge_requests/commit_templates.md) in your project and use `defaultMergeCommitMessage`. |

## GitLab 14.0

Fields [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63293) in GitLab 14.0:

### GraphQL Mutations

| Argument name        | Mutation                 | Deprecated in | Use instead                |
| -------------------- | --------------------     | ------------- | -------------------------- |
| `updated_ids`        | `todosMarkAllDone`       | 13.2          | `todos`                    |
| `updated_ids`        | `todoRestoreMany`        | 13.2          | `todos`                    |
| `global_id`          | `dastScannerProfileCreate`| 13.6          | `todos`                    |
| -                    | `addAwardEmoji`          | 13.2          | `awardEmojiAdd`            |
| -                    | `removeAwardEmoji`       | 13.2          | `awardEmojiRemove`         |
| -                    | `toggleAwardEmoji`       | 13.2          | `ToggleAwardEmoji`         |
| -                    | `runDastScan`            | 13.5          | `dastOnDemandScanCreate`   |
| -                    | `dismissVulnerability`   | 13.5          | `vulnerabilityDismiss`     |
| -                    | `revertVulnerabilityToDetected`   | 13.5          | `vulnerabilityRevertToDetected`     |

### GraphQL Types

| Field name           | GraphQL type             | Deprecated in | Use instead                |
| -------------------- | --------------------     | ------------- | -------------------------- |
| `blob`               | `SnippetType`            | 13.3          | `blobs`                    |
| `global_id`          | `DastScannerProfileType` | 13.6          | `blobs`                    |
| `vulnerabilities_count_by_day_and_severity` | `GroupType`, `QueryType` | 13.3          | None. Plaintext tokens no longer supported for security reasons. |

## GitLab 13.6

Prior to GitLab 14.0, deprecated items could be removed in `XX.6` releases.

Fields [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44866) in GitLab 13.6:

| Field name           | GraphQL type             | Deprecated in | Use instead                |
|----------------------|--------------------------|---------------|----------------------------|
| `date`               | `Timelog`                | 12.10         | `spentAt`                  |
| `designs`            | `Issue`, `EpicIssue`     | 12.2          | `designCollection`         |
| `latestPipeline`     | `Commit`                 | 12.5          | `pipelines`                |
| `mergeCommitMessage` | `MergeRequest`           | 11.8          | `latestMergeCommitMessage` |
| `token`              | `GrafanaIntegration`     | 12.7          | None. Plaintext tokens no longer supported for security reasons. |
