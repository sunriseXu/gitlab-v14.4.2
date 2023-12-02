---
stage: Govern
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Vulnerabilities API **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10242) in GitLab 12.6.

NOTE:
The former Vulnerabilities API was renamed to Vulnerability Findings API
and its documentation was moved to [a different location](vulnerability_findings.md).
This document now describes the new Vulnerabilities API that provides access to
[Vulnerabilities](https://gitlab.com/groups/gitlab-org/-/epics/634).

WARNING:
This API is in the process of being deprecated and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases. Please use the
[GraphQL API](graphql/reference/index.md#queryvulnerabilities)
instead. See the [GraphQL examples](#replace-vulnerability-rest-api-with-graphql) to get started.

Every API call to vulnerabilities must be [authenticated](index.md#authentication).

Vulnerability permissions inherit permissions from their project. If a project is
private, and a user isn't a member of the project to which the vulnerability
belongs, requests to that project returns a `404 Not Found` status code.

## Single vulnerability

Gets a single vulnerability

```plaintext
GET /vulnerabilities/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID of a Vulnerability to get |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/1"
```

Example response:

```json
{
  "id": 1,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "opened",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Confirm vulnerability

Confirms a given vulnerability. Returns status code `304` if the vulnerability is already confirmed.

If an authenticated user does not have permission to
[confirm vulnerabilities](../user/permissions.md#project-members-permissions),
this request results in a `403` status code.

```plaintext
POST /vulnerabilities/:id/confirm
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID of a vulnerability to confirm |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/confirm"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "confirmed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Resolve vulnerability

Resolves a given vulnerability. Returns status code `304` if the vulnerability is already resolved.

If an authenticated user does not have permission to
[resolve vulnerabilities](../user/permissions.md#project-members-permissions),
this request results in a `403` status code.

```plaintext
POST /vulnerabilities/:id/resolve
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID of a Vulnerability to resolve |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/resolve"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "resolved",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Dismiss vulnerability

Dismisses a given vulnerability. Returns status code `304` if the vulnerability is already dismissed.

If an authenticated user does not have permission to
[dismiss vulnerabilities](../user/permissions.md#project-members-permissions),
this request results in a `403` status code.

```plaintext
POST /vulnerabilities/:id/dismiss
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID of a vulnerability to dismiss |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "closed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Revert vulnerability to detected state

Reverts a given vulnerability to detected state. Returns status code `304` if the vulnerability is already in detected state.

If an authenticated user does not have permission to
[revert vulnerability to detected state](../user/permissions.md#project-members-permissions),
this request results in a `403` status code.

```plaintext
POST /vulnerabilities/:id/revert
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID of a vulnerability to revert to detected state |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

Example response:

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "detected",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "updated_by_id": null,
  "last_edited_by_id": null,
  "closed_by_id": null,
  "start_date": null,
  "due_date": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "last_edited_at": null,
  "closed_at": null
}
```

## Replace Vulnerability REST API with GraphQL

To prepare for the [upcoming deprecation](https://gitlab.com/groups/gitlab-org/-/epics/5118) of
the Vulnerability REST API endpoint, use the examples below to perform the equivalent operations
with the GraphQL API.

### GraphQL - Single vulnerability

Use [`Query.vulnerability`](graphql/reference/index.md#queryvulnerability).

```graphql
{
  vulnerability(id: "gid://gitlab/Vulnerability/20345379") {
    title
    description
    state
    severity
    reportType
    project {
      id
      name
      fullPath
    }
    detectedAt
    confirmedAt
    resolvedAt
    resolvedBy {
      id
      username
    }
  }
}
```

Example response:

```json
{
  "data": {
    "vulnerability": {
      "title": "Improper Input Validation in railties",
      "description": "A remote code execution vulnerability in development mode Rails beta3 can allow an attacker to guess the automatically generated development mode secret token. This secret token can be used in combination with other Rails internals to escalate to a remote code execution exploit.",
      "state": "RESOLVED",
      "severity": "CRITICAL",
      "reportType": "DEPENDENCY_SCANNING",
      "project": {
        "id": "gid://gitlab/Project/6102100",
        "name": "security-reports",
        "fullPath": "gitlab-examples/security/security-reports"
      },
      "detectedAt": "2021-10-14T03:13:41Z",
      "confirmedAt": "2021-12-14T01:45:56Z",
      "resolvedAt": "2021-12-14T01:45:59Z",
      "resolvedBy": {
        "id": "gid://gitlab/User/480804",
        "username": "thiagocsf"
      }
    }
  }
}
```

### GraphQL - Confirm vulnerability

Use [`Mutation.vulnerabilityConfirm`](graphql/reference/index.md#mutationvulnerabilityconfirm).

```graphql
mutation {
  vulnerabilityConfirm(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Example response:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "CONFIRMED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Resolve vulnerability

Use [`Mutation.vulnerabilityResolve`](graphql/reference/index.md#mutationvulnerabilityresolve).

```graphql
mutation {
  vulnerabilityResolve(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Example response:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "RESOLVED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Dismiss vulnerability

Use [`Mutation.vulnerabilityDismiss`](graphql/reference/index.md#mutationvulnerabilitydismiss).

```graphql
mutation {
  vulnerabilityDismiss(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Example response:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DISMISSED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Revert vulnerability to detected state

Use [`Mutation.vulnerabilityRevertToDetected`](graphql/reference/index.md#mutationvulnerabilityreverttodetected).

```graphql
mutation {
  vulnerabilityRevertToDetected(input: { id: "gid://gitlab/Vulnerability/20345379"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Example response:

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DETECTED"
      },
      "errors": []
    }
  }
}
```
