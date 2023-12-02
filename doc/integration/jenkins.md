---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jenkins integration **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/246756) to GitLab Free in 13.7.

You can trigger a build in Jenkins when you push code to your repository or
create a merge request in GitLab. The Jenkins pipeline status displays on merge
requests widgets and on the GitLab project's home page.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of the Jenkins integration for GitLab, see
[GitLab workflow with Jira issues and Jenkins pipelines](https://youtu.be/Jn-_fyra7xQ).

Use the Jenkins integration when:

- You plan to migrate your CI from Jenkins to [GitLab CI/CD](../ci/index.md)
  in the future, but need an interim solution.
- You're invested in [Jenkins plugins](https://plugins.jenkins.io/) and choose
  to keep using Jenkins to build your apps.

NOTE:
This documentation focuses only on how to configure a Jenkins *integration* with
GitLab. Learn how to set up Jenkins [on your local machine](../development/integrations/jenkins.md)
in the developer documentation, and how to migrate from Jenkins to GitLab CI/CD in the
[Migrating from Jenkins](../ci/migration/jenkins.md) documentation.

The Jenkins integration requires configuration in both GitLab and Jenkins.

## Grant Jenkins access to the GitLab project

Grant a GitLab user access to the relevant GitLab projects.

1. Create a new GitLab user, or choose an existing GitLab user.

   This account is used by Jenkins to access the GitLab projects. We recommend creating a GitLab
   user for only this purpose. If you use a person's account, and their account is deactivated or
   deleted, the Jenkins integration stops working.

1. Grant the user permission to the GitLab projects.

   If you're integrating Jenkins with many GitLab projects, consider granting the
   user administrator access. Otherwise, add the user to each project
   and grant the Maintainer role.

## Grant Jenkins access to the GitLab API

Create a personal access token to authorize Jenkins to access GitLab.

1. Sign in to GitLab as the user to be used with Jenkins.
1. On the top bar, in the top right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Create a [personal access token](../user/profile/personal_access_tokens.md) and
   select the **API** scope.
1. Copy the personal access token. You need it to [configure the Jenkins server](#configure-the-jenkins-server).

## Configure the Jenkins server

Install and configure the Jenkins plugin. The plugin must be installed and configured to
authorize the connection to GitLab.

1. On the Jenkins server, select **Manage Jenkins > Manage Plugins**.
1. Install the [Jenkins GitLab Plugin](https://wiki.jenkins.io/display/JENKINS/GitLab+Plugin).
1. Select **Manage Jenkins > Configure System**.
1. In the **GitLab** section, select **Enable authentication for '/project' end-point**.
1. Select **Add**, then choose **Jenkins Credential Provider**.
1. Select **GitLab API token** as the token type.
1. Enter the GitLab personal access token's value in **API Token** and select **Add**.
1. Enter the GitLab server's URL in **GitLab host URL**.
1. To test the connection, select **Test Connection**.

   ![Jenkins plugin configuration](img/jenkins_gitlab_plugin_config.png)

For more information, see
[Jenkins-to-GitLab authentication](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication).

## Configure the Jenkins project

Set up the Jenkins project you intend to run your build on.

1. On your Jenkins instance, go to **New Item**.
1. Enter the project's name.
1. Select **Freestyle** or **Pipeline** and select **OK**.
   We recommend a Freestyle project, because the Jenkins plugin updates the build status on
   GitLab. In a Pipeline project, you must configure a script to update the status on GitLab.
1. Choose your GitLab connection from the dropdown list.
1. Select **Build when a change is pushed to GitLab**.
1. Select the following checkboxes:
   - **Accepted Merge Request Events**
   - **Closed Merge Request Events**
1. Specify how the build status is reported to GitLab:
   - If you created a **Freestyle** project, in the **Post-build Actions** section, choose
   **Publish build status to GitLab**.
   - If you created a **Pipeline** project, you must use a Jenkins Pipeline script to update the status on
   GitLab.

     Example Jenkins Pipeline script:

      ```groovy
      pipeline {
         agent any

         stages {
            stage('gitlab') {
               steps {
                  echo 'Notify GitLab'
                  updateGitlabCommitStatus name: 'build', state: 'pending'
                  updateGitlabCommitStatus name: 'build', state: 'success'
               }
            }
         }
      }
      ```

      For more Jenkins Pipeline script examples, go to the [Jenkins GitLab plugin repository on GitHub](https://github.com/jenkinsci/gitlab-plugin#scripted-pipeline-jobs).

## Configure the GitLab project

Configure the GitLab integration with Jenkins in one of the following ways.

### Configure a Jenkins integration (recommended)

GitLab recommends this approach for Jenkins integrations because it is easier to configure
than the [webhook integration](#configure-a-webhook).

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Jenkins**.
1. Select the **Active** checkbox.
1. Select the events you want GitLab to trigger a Jenkins build for:
   - Push
   - Merge request
   - Tag push
1. Enter the **Jenkins server URL**.
1. Optional. Clear the **Enable SSL verification** checkbox to disable [SSL verification](../user/project/integrations/index.md#manage-ssl-verification).
1. Enter the **Project name**.

   The project name should be URL-friendly, where spaces are replaced with underscores. To ensure
   the project name is valid, copy it from your browser's address bar while viewing the Jenkins
   project.
1. If your Jenkins server requires
   authentication, enter the **Username** and **Password**.
1. To test the connection to Jenkins, select **Test settings**.
1. Select **Save changes**.

### Configure a webhook

If you are unable to provide GitLab with your Jenkins server login, you can use this option
to integrate GitLab and Jenkins.

1. In the configuration of your Jenkins job, in the GitLab configuration section, select **Advanced**.
1. Under **Secret Token**, select **Generate**.
1. Copy the token, and save the job configuration.
1. In GitLab, create a webhook for your project, enter the trigger URL
   (such as `https://JENKINS_URL/project/YOUR_JOB`) and paste the token in **Secret Token**.
1. To test the webhook, select **Test**.

## Related topics

- For a real use case, read the blog post
  [Continuous integration: From Jenkins to GitLab using Docker](https://about.gitlab.com/blog/2017/07/27/docker-my-precious/).
- See the ['GitLab vs. Jenkins' comparison page](https://about.gitlab.com/devops-tools/jenkins-vs-gitlab/)
  for information on how moving to a single application for the entire software development
  lifecycle can decrease hours spent on maintaining toolchains by 10% or more.

## Troubleshooting

### Error during GitLab configuration - "Connection failed. Please check your settings"

If you get this error message while configuring GitLab, the following are possible causes:

- GitLab is unable to reach your Jenkins instance at the address. If your GitLab instance is self-managed, try pinging the
  Jenkins instance at the domain provided on the GitLab instance.
- The Jenkins instance is at a local address and is not included in the
  [GitLab installation's allowlist](../security/webhooks.md#create-an-allowlist-for-local-requests).
- The credentials for the Jenkins instance do not have sufficient access or are invalid.
- The **Enable authentication for `/project` end-point** checkbox is not selected in your [Jenkin's plugin configuration](#configure-the-jenkins-server).

### Error in merge requests - "Could not connect to the CI server"

You might get the `Could not connect to the CI server` error if GitLab did not
receive a build status update from Jenkins via the [Commit Status API](../api/commits.md#commit-status).

This issue occurs when Jenkins is not properly
configured or there is an error reporting the status via the API.

To fix this issue, ensure you:

1. [Configure the Jenkins server](#configure-the-jenkins-server) for GitLab API access.
1. [Configure the Jenkins project](#configure-the-jenkins-project), including the
   'Publish build status to GitLab' post-build action.

### Merge request event does not trigger a Jenkins pipeline

This issue can occur when the request exceeds the
[webhook timeout](../user/project/integrations/webhooks.md#webhook-fails-or-multiple-webhook-requests-are-triggered),
which is set to 10 seconds by default.

Check the [service hook logs](../user/project/integrations/index.md#troubleshooting-integrations)
for request failures or check the `/var/log/gitlab/gitlab-rails/production.log`
file for messages like:

```plaintext
WebHook Error => Net::ReadTimeout
```

or

```plaintext
WebHook Error => execution expired
```

Or check for duplicate messages in `/var/log/gitlab/gitlab-rail`, like:

```plaintext
2019-10-25_04:22:41.25630 2019-10-25T04:22:41.256Z 1584 TID-ovowh4tek WebHookWorker JID-941fb7f40b69dff3d833c99b INFO: start
2019-10-25_04:22:41.25630 2019-10-25T04:22:41.256Z 1584 TID-ovowh4tek WebHookWorker JID-941fb7f40b69dff3d833c99b INFO: start
```

To fix this issue:

1. Increase the `gitlab_rails['webhook_timeout']` value in the `gitlab.rb`
   configuration file.
1. [Restart](../administration/restart_gitlab.md) GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

### Enable job logs in Jenkins

To troubleshoot an integration issue, you can enable job logs in Jenkins to get
more details about your builds.

To enable job logs in Jenkins:

1. Go to **Dashboard > Manage Jenkins > System Log**.
1. Select **Add new log recorder**.
1. Enter a name for the log recorder.
1. On the next screen, select **Add** and enter `com.dabsquared.gitlabjenkins`.
1. Make sure that the Log Level is **All** and select **Save**.

To view your logs:

1. Run a build.
1. Go to **Dashboard > Manage Jenkins > System Log**.
1. Select your logger and check the logs.
