---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Configure OpenID Connect in AWS to retrieve temporary credentials

In this tutorial, we'll show you how to use a GitLab CI/CD job with a JSON web token (JWT) to retrieve temporary credentials from AWS without needing to store secrets.
To do this, you must configure OpenID Connect (OIDC) for ID federation between GitLab and AWS. For background and requirements for integrating GitLab using OIDC, see [Connect to cloud services](../index.md).

To complete this tutorial:

1. [Add the identity provider](#add-the-identity-provider)
1. [Configure the role and trust](#configure-a-role-and-trust)
1. [Retrieve a temporary credential](#retrieve-temporary-credentials)

## Add the identity provider

Create GitLab as a IAM OIDC provider in AWS following these [instructions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

Include the following information:

- **Provider URL**: The address of your GitLab instance, such as `https://gitlab.com` or `http://gitlab.example.com`.
- **Audience**: The address of your GitLab instance, such as `https://gitlab.com` or `http://gitlab.example.com`.
  - The address must include `https://`.
  - Do not include a trailing slash.

## Configure a role and trust

After you create the identity provider, configure a [web identity role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html) with conditions for limiting access to GitLab resources. Temporary credentials are obtained using [AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html), so set the `Action` to [sts:AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html).

For the full list of supported filtering types, see [Connect to cloud services](../index.md#configure-a-conditional-role-with-oidc-claims).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/gitlab.example.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.example.com:sub": "project_path:mygroup/myproject:ref_type:branch:ref:main"
        }
      }
    }
  ]
}
```

After the role is created, attach a policy defining permissions to an AWS service (S3, EC2, Secrets Manager).

## Retrieve temporary credentials

After you configure the OIDC and role, the GitLab CI/CD job can retrieve a temporary credential from [AWS Security Token Service (STS)](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html).

```yaml
assume role:
  script:
    - >
      export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s"
      $(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token $CI_JOB_JWT_V2
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text))
    - aws sts get-caller-identity
```

- `CI_JOB_JWT_V2`: Predefined variable.
- `ROLE_ARN`: The role ARN defined in this [step](#configure-a-role-and-trust).

## Working example

See this [reference project](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) for provisioning OIDC in AWS using Terraform and a sample script to retrieve temporary credentials.

## Troubleshooting

### `An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity`

This error can occur for multiple reasons:

- The cloud administrator has not configured the project to use OIDC with GitLab.
- The role is restricted from being run on the branch or tag. See [configure a conditional role](../index.md).
- `StringEquals` is used instead of `StringLike` when using a wildcard condition. See [related issue](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934).
