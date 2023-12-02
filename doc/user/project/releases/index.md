---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Releases **(FREE)**

In GitLab, a release enables you to create a snapshot of your project for your users, including
installation packages and release notes. You can create a GitLab release on any branch. Creating a
release also creates a [Git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) to mark the
release point in the source code.

WARNING:
Deleting a Git tag associated with a release also deletes the release.

A release can include:

- A snapshot of the source code of your repository.
- [Generic packages](../../packages/generic_packages/index.md) created from job artifacts.
- Other metadata associated with a released version of your code.
- Release notes.

When you [create a release](#create-a-release):

- GitLab automatically archives source code and associates it with the release.
- GitLab automatically creates a JSON file that lists everything in the release,
  so you can compare and audit releases. This file is called [release evidence](#release-evidence).

When you create a release, or after, you can:

- Add release notes.
- Add a message for the Git tag associated with the release.
- [Associate milestones with it](#associate-milestones-with-a-release).
- Attach [release assets](release_fields.md#release-assets), like runbooks or packages.

## View releases

To view a list of releases:

- On the left sidebar, select **Deployments > Releases**, or

- On the project's overview page, if at least one release exists, select the number of releases.

  ![Number of Releases](img/releases_count_v13_2.png "Incremental counter of Releases")

  - On public projects, this number is visible to all users.
  - On private projects, this number is visible to users with Reporter
    [permissions](../../permissions.md#project-members-permissions) or higher.

### Sort releases

To sort releases by **Released date** or **Created date**, select from the sort order dropdown list. To
switch between ascending or descending order, select **Sort order**.

![Sort releases dropdown list options](img/releases_sort_v13_6.png)

## Create a release

You can create a release:

- [Using a job in your CI/CD pipeline](#creating-a-release-by-using-a-cicd-job).
- [In the Releases page](#create-a-release-in-the-releases-page).
- [In the Tags page](#create-a-release-in-the-tags-page).
- Using the [Releases API](../../../api/releases/index.md#create-a-release).

We recommend creating a release as one of the last steps in your CI/CD pipeline.

### Create a release in the Releases page

Prerequisites:

- You must have at least the Developer role for a project. For more information, read
[Release permissions](#release-permissions).

To create a release in the Releases page:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Deployments > Releases** and select **New release**.
1. From the [**Tag name**](release_fields.md#tag-name) dropdown, either:
   - Select an existing Git tag. Selecting an existing tag that is already associated with a release
     results in a validation error.
   - Enter a new Git tag name.
      1. From the **Create from** dropdown, select a branch or commit SHA to use when creating the
         new tag.
1. Optional. Enter additional information about the release, including:
   - [Title](release_fields.md#title).
   - [Milestones](#associate-milestones-with-a-release).
   - [Release notes](release_fields.md#release-notes-description).
   - Whether or not to include the [Tag message](../../../topics/git/tags.md).
   - [Asset links](release_fields.md#links).
1. Select **Create release**.

### Create a release in the Tags page

To create a release in the Tags page, add release notes to either an existing or a new Git tag.

To add release notes to a new Git tag:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Tags**.
1. Select **New tag**.
1. Optional. Enter a tag message in the **Message** text box.
1. In the **Release notes** text box, enter the release's description.
   You can use Markdown and drag and drop files to this text box.
1. Select **Create tag**.

To edit release notes of an existing Git tag:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Tags**.
1. Select **Edit release notes** (**{pencil}**).
1. In the **Release notes** text box, enter the release's description.
   You can use Markdown and drag and drop files to this text box.
1. Select **Save changes**.

### Creating a release by using a CI/CD job

You can create a release directly as part of the GitLab CI/CD pipeline by using the
[`release` keyword](../../../ci/yaml/index.md#release) in the job definition.

The release is created only if the job processes without error. If the API returns an error during
release creation, the release job fails.

Methods for creating a release using a CI/CD job include:

- [Create a release when a Git tag is created](release_cicd_examples.md#create-a-release-when-a-git-tag-is-created).
- [Create a release when a commit is merged to the default branch](release_cicd_examples.md#create-a-release-when-a-commit-is-merged-to-the-default-branch).
- [Create release metadata in a custom script](release_cicd_examples.md#create-release-metadata-in-a-custom-script).

### Use a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority,
which is used to verify the peer when the `release-cli` creates a release through the API using HTTPS with custom certificates.
The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the
[text representation of the X.509 PEM public-key certificate](https://tools.ietf.org/html/rfc7468#section-5.1)
or the `path/to/file` containing the certificate authority.
For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
release:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  script:
    - echo "Create release"
  release:
    name: 'My awesome release'
    tag_name: '$CI_COMMIT_TAG'
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a
[custom variable in the UI](../../../ci/variables/index.md#custom-cicd-variables),
either as a `file`, which requires the path to the certificate, or as a variable,
which requires the text representation of the certificate.

### Create multiple releases in a single pipeline

A pipeline can have multiple `release` jobs, for example:

```yaml
ios-release:
  script:
    - echo "iOS release job"
  release:
    tag_name: v1.0.0-ios
    description: 'iOS release v1.0.0'

android-release:
  script:
    - echo "Android release job"
  release:
    tag_name: v1.0.0-android
    description: 'Android release v1.0.0'
```

### Release assets as Generic packages

You can use [Generic packages](../../packages/generic_packages/index.md) to host your release assets.
For a complete example, see the [Release assets as Generic packages](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs/examples/release-assets-as-generic-package/)
project.

## Upcoming releases

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38105) in GitLab 12.1.

You can create a release ahead of time by using the [Releases API](../../../api/releases/index.md#upcoming-releases).
When you set a future `released_at` date, an **Upcoming Release** badge is displayed next to the
release tag. When the `released_at` date and time has passed, the badge is automatically removed.

![An upcoming release](img/upcoming_release_v12_7.png)

## Historical releases

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/199429) in GitLab 15.2.

You can create a release in the past using either the
[Releases API](../../../api/releases/index.md#historical-releases) or the UI. When you set
a past `released_at` date, an **Historical release** badge is displayed next to
the release tag. Due to being released in the past, [release evidence](#release-evidence)
is not available.

## Edit a release

Only users with at least the Developer role can edit releases.
Read more about [Release permissions](#release-permissions).

To edit the details of a release:

1. On the left sidebar, select **Deployments > Releases**.
1. In the top-right corner of the release you want to modify, select **Edit this release** (the pencil icon).
1. On the **Edit Release** page, change the release's details.
1. Select **Save changes**.

You can edit the release title, notes, associated milestones, and asset links.
To change the release date use the
[Releases API](../../../api/releases/index.md#update-a-release).

## Delete a release

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213862) in GitLab 15.2

When you delete a release, its assets are also deleted. However, the associated
Git tag is not deleted.

Prerequisites:

- You must have at least the Developer role. Read more about [Release permissions](#release-permissions).

To delete a release in the UI:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Deployments > Releases**.
1. In the top-right corner of the release you want to delete, select **Edit this release** (**{pencil}**).
1. On the **Edit Release** page, select **Delete**.
1. Select **Delete release**.

## Associate milestones with a release

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29020) in GitLab 12.5.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/39467) to edit milestones in the UI in GitLab 13.0.

You can associate a release with one or more [project milestones](../milestones/index.md#project-milestones-and-group-milestones).

[GitLab Premium](https://about.gitlab.com/pricing/) customers can specify [group milestones](../milestones/index.md#project-milestones-and-group-milestones) to associate with a release.

You can do this in the user interface, or by including a `milestones` array in your request to
the [Releases API](../../../api/releases/index.md#create-a-release).

In the user interface, to associate milestones to a release:

1. On the left sidebar, select **Deployments > Releases**.
1. In the top-right corner of the release you want to modify, select **Edit this release** (the pencil icon).
1. From the **Milestones** list, select each milestone you want to associate. You can select multiple milestones.
1. Select **Save changes**.

On the **Deployments > Releases** page, the **Milestone** is listed in the top
section, along with statistics about the issues in the milestones.

![A Release with one associated milestone](img/release_with_milestone_v12_9.png)

Releases are also visible on the **Issues > Milestones** page, and when you select a milestone
on this page.

Here is an example of milestones with no releases, one release, and two releases, respectively.

![Milestones with and without Release associations](img/milestone_list_with_releases_v12_5.png)

NOTE:
A subgroup's project releases cannot be associated with a supergroup's milestone. To learn
more, read issue #328054,
[Releases cannot be associated with a supergroup milestone](https://gitlab.com/gitlab-org/gitlab/-/issues/328054).

## Get notified when a release is created

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26001) in GitLab 12.4.

You can be notified by email when a new release is created for your project.

To subscribe to notifications for releases:

1. On the left sidebar, select **Project information**.
1. Select **Notification setting** (the bell icon).
1. In the list, select **Custom**.
1. Select the **New release** checkbox.
1. Close the dialog box to save.

## Prevent unintentional releases by setting a deploy freeze

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29382) in GitLab 13.0.
> - The ability to delete freeze periods through the UI was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/212451) in GitLab 14.3.

Prevent unintended production releases during a period of time you specify by
setting a [*deploy freeze* period](../../../ci/environments/deployment_safety.md).
Deploy freezes help reduce uncertainty and risk when automating deployments.

A maintainer can set a deploy freeze window in the user interface or by using the [Freeze Periods API](../../../api/freeze_periods.md) to set a `freeze_start` and a `freeze_end`, which
are defined as [crontab](https://crontab.guru/) entries.

If the job that's executing is within a freeze period, GitLab CI/CD creates an environment
variable named `$CI_DEPLOY_FREEZE`.

To prevent the deployment job from executing, create a `rules` entry in your
`.gitlab-ci.yml`, for example:

```yaml
deploy_to_production:
  stage: deploy
  script: deploy_to_prod.sh
  rules:
    - if: $CI_DEPLOY_FREEZE == null
  environment: production
```

To set a deploy freeze window in the UI, complete these steps:

1. Sign in to GitLab as a user with the Maintainer role.
1. On the left sidebar, select **Project information**.
1. In the left navigation menu, go to **Settings > CI/CD**.
1. Scroll to **Deploy freezes**.
1. Select **Expand** to see the deploy freeze table.
1. Select **Add deploy freeze** to open the deploy freeze modal.
1. Enter the start time, end time, and time zone of the desired deploy freeze period.
1. Select **Add deploy freeze** in the modal.
1. After the deploy freeze is saved, you can edit it by selecting the edit button (**{pencil}**) and remove it by selecting the delete button (**{remove}**).
   ![Deploy freeze modal for setting a deploy freeze period](img/deploy_freeze_v14_3.png)

If a project contains multiple freeze periods, all periods apply. If they overlap, the freeze covers the
complete overlapping period.

For more information, see [Deployment safety](../../../ci/environments/deployment_safety.md).

## Release evidence

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26019) in GitLab 12.6.

Each time a release is created, GitLab takes a snapshot of data that's related to it.
This data is saved in a JSON file and called *release evidence*. The feature
includes test artifacts and linked milestones to facilitate
internal processes, like external audits.

To access the release evidence, on the Releases page, select the link to the JSON file that's listed
under the **Evidence collection** heading.

You can also [use the API](../../../api/releases/index.md#collect-release-evidence) to
generate release evidence for an existing release. Because of this, each release
can have multiple release evidence snapshots. You can view the release evidence and
its details on the Releases page.

When the issue tracker is disabled, release evidence [can't be downloaded](https://gitlab.com/gitlab-org/gitlab/-/issues/208397).

Here is an example of a release evidence object:

```json
{
  "release": {
    "id": 5,
    "tag_name": "v4.0",
    "name": "New release",
    "project": {
      "id": 20,
      "name": "Project name",
      "created_at": "2019-04-14T11:12:13.940Z",
      "description": "Project description"
    },
    "created_at": "2019-06-28 13:23:40 UTC",
    "description": "Release description",
    "milestones": [
      {
        "id": 11,
        "title": "v4.0-rc1",
        "state": "closed",
        "due_date": "2019-05-12 12:00:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "issues": [
          {
            "id": 82,
            "title": "The top-right popup is broken",
            "author_name": "John Doe",
            "author_email": "john@doe.com",
            "state": "closed",
            "due_date": "2019-05-10 12:00:00 UTC"
          },
          {
            "id": 89,
            "title": "The title of this page is misleading",
            "author_name": "Jane Smith",
            "author_email": "jane@smith.com",
            "state": "closed",
            "due_date": "nil"
          }
        ]
      },
      {
        "id": 12,
        "title": "v4.0-rc2",
        "state": "closed",
        "due_date": "2019-05-30 18:30:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "issues": []
      }
    ],
    "report_artifacts": [
      {
        "url":"https://gitlab.example.com/root/project-name/-/jobs/111/artifacts/download"
      }
    ]
  }
}
```

### Collect release evidence **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/199065) in GitLab 12.10.

When a release is created, release evidence is automatically collected. To initiate evidence collection any other time, use an [API call](../../../api/releases/index.md#collect-release-evidence). You can collect release evidence multiple times for one release.

Evidence collection snapshots are visible on the Releases page, along with the timestamp the evidence was collected.

### Include report artifacts as release evidence **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32773) in GitLab 13.2.

When you create a release, if [job artifacts](../../../ci/yaml/index.md#artifactsreports) are included in the last pipeline that ran, they are automatically included in the release as release evidence.

Although job artifacts normally expire, artifacts included in release evidence do not expire.

To enable job artifact collection you must specify both:

1. [`artifacts:paths`](../../../ci/yaml/index.md#artifactspaths)
1. [`artifacts:reports`](../../../ci/yaml/index.md#artifactsreports)

```yaml
ruby:
  script:
    - gem install bundler
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

If the pipeline ran successfully, when you create your release, the `rspec.xml` file is saved as
release evidence.

If you [schedule release evidence collection](#schedule-release-evidence-collection),
some artifacts may already be expired by the time of evidence collection. To avoid this you can use
the [`artifacts:expire_in`](../../../ci/yaml/index.md#artifactsexpire_in)
keyword. Learn more in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/222351).

### Schedule release evidence collection

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23697) in GitLab 12.8.

In the API:

- If you specify a future `released_at` date, the release becomes an **Upcoming release**
  and the evidence is collected on the date of the release. You cannot collect
  release evidence before then.
- If you specify a past `released_at` date, the release becomes an **Historical
  release** and no evidence is collected.
- If you do not specify a `released_at` date, release evidence is collected on the
  date the release is created.

## Release permissions

> [The permission model for create, update and delete actions was fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/327505) in GitLab 14.1.

### View a release and download assets

> [Changes were made to the Guest role access](https://gitlab.com/gitlab-org/gitlab/-/issues/335209) in GitLab 14.5.

- Users with at least the Reporter role
  have read and download access to the project releases.
- Users with the Guest role
  have read and download access to the project releases.
  This includes associated Git-tag-names, release description, author information of the releases.
  However, other repository-related information, such as [source code](release_fields.md#source-code), [release evidence](#release-evidence) are redacted.

### Create, update, and delete a release and its assets

- Users with at least the Developer role
  have write access to the project releases and assets.
- If a release is associated with a [protected tag](../protected_tags.md),
  the user must be [allowed to create the protected tag](../protected_tags.md#configuring-protected-tags) too.

As an example of release permission control, you can allow only
users with at least the Maintainer role
to create, update, and delete releases by protecting the tag with a wildcard (`*`),
and set **Maintainer** in the **Allowed to create** column.

## Release Metrics **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259703) in GitLab Premium 13.9.

Group-level release metrics are available by navigating to **Group > Analytics > CI/CD**.
These metrics include:

- Total number of releases in the group
- Percentage of projects in the group that have at least one release

## Working example project

The Guided Exploration project [Utterly Automated Software and Artifact Versioning with GitVersion](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning) demonstrates:

- Using GitLab releases.
- Using the GitLab `release-cli`.
- Creating a generic package.
- Linking the package to the release.
- Using a tool called [GitVersion](https://gitversion.net/) to automatically determine and increment versions for complex repositories.

You can copy the example project to your own group or instance for testing. More details on what other GitLab CI patterns are demonstrated are available at the project page.

## Troubleshooting

### Getting `403 Forbidden` or `Something went wrong while creating a new release` errors when creating, updating or deleting releases and their assets

If the release is associated with a [protected tag](../protected_tags.md),
the UI/API request might result in an authorization failure.
Make sure that the user or a service/bot account is allowed to
[create the protected tag](../protected_tags.md#configuring-protected-tags) too.

See [the release permissions](#release-permissions) for more information.

### Note about storage

Note that the feature is built on top of Git tags, so virtually no extra data is needed besides to create the release itself. Additional assets and the release evidence that is automatically generated consume storage.
