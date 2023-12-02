---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting SAML **(FREE)**

This page contains possible solutions for problems you might encounter when using:

- [SAML SSO for GitLab.com groups](index.md).
- The self-managed instance-level [SAML OmniAuth Provider](../../../integration/saml.md).

## SAML debugging tools

SAML responses are base64 encoded, so we recommend the following browser plugins to decode them on the fly:

- [SAML-tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) for Firefox.
- [SAML Message Decoder](https://chrome.google.com/webstore/detail/saml-message-decoder/mpabchoaimgbdbbjjieoaeiibojelbhm?hl=en) for Chrome.

Specific attention should be paid to:

- The NameID, which we use to identify which user is signing in. If the user has previously signed in, this [must match the value we have stored](#verifying-nameid).
- The presence of a `X509Certificate`, which we require to verify the response signature.
- The `SubjectConfirmation` and `Conditions`, which can cause errors if misconfigured.

### Generate a SAML response

Use SAML responses to preview the attribute names and values sent in the assertions list while attempting to sign in
using an identity provider.

To generate a SAML Response:

1. Install one of the browser debugging tools previously mentioned.
1. Open a new browser tab.
1. Open the SAML tracer console:
   - Chrome: On a context menu on the page, select **Inspect**, then select the **SAML** tab in the opened developer
     console.
   - Firefox: Select the SAML-tracer icon located on the browser toolbar.
1. Go to the GitLab single sign-on URL for the group in the same browser tab with the SAML tracer open.
1. Select **Authorize** or attempt to log in. A SAML response is displayed in the tracer console that resembles this
   [example SAML response](index.md#example-saml-response).
1. Within the SAML tracer, select the **Export** icon to save the response in JSON format.

## GitLab SAML Testing Environments

To troubleshoot, [a complete GitLab with SAML testing environment using Docker compose](https://gitlab.com/gitlab-com/support/toolbox/replication/tree/master/compose_files)
is available.

If you only require a SAML provider for testing, a [quick start guide to start a Docker container](../../../administration/troubleshooting/test_environments.md#saml) with a plug and play SAML 2.0 Identity Provider (identity provider) is available.

You can test the SaaS feature locally by [enabling SAML for groups on a self-managed instance](../../../integration/saml.md#configuring-group-saml-on-a-self-managed-gitlab-instance).

## Verifying configuration

For convenience, we've included some [example resources](../../../user/group/saml_sso/example_saml_config.md) used by our Support Team. While they may help you verify the SAML app configuration, they are not guaranteed to reflect the current state of third-party products.

## Searching Rails log for a SAML response **(FREE SELF)**

You can find the base64-encoded SAML Response in the [`production_json.log`](../../../administration/logs/index.md#production_jsonlog).
This response is sent from the identity provider, and contains user information that is consumed by GitLab.
Many errors in the SAML integration can be solved by decoding this response and comparing it to the SAML settings in the GitLab configuration file.

For example, with SAML for groups,
you should be able to find the base64 encoded SAML response by searching with the following filters:

- `json.meta.caller_id`: `Groups::OmniauthCallbacksController#group_saml`
- `json.meta.user` or `json.username`: `username`
- `json.method`: `POST`
- `json.path`: `/groups/GROUP-PATH/-/saml/callback`

In a relevant log entry, the `json.params` should provide a valid response with:

- `"key": "SAMLResponse"` and the `"value": (full SAML response)`,
- `"key": "RelayState"` with `"value": "/group-path"`, and
- `"key": "group_id"` with `"value": "group-path"`.

In some cases, if the SAML response is lengthy, you may receive a `"key": "truncated"` with `"value":"..."`.
In these cases, use one of the [SAML debugging tools](#saml-debugging-tools), or for SAML SSO for groups,
a group owner can get a copy of the SAML response from when they select
the "Verify SAML Configuration" button on the group SSO Settings page.

Use a base64 decoder to see a human-readable version of the SAML response.

## Configuration errors

### Invalid audience

This error means that the identity provider doesn't recognize GitLab as a valid sender and
receiver of SAML requests. Make sure to:

- Add the GitLab callback URL to the approved audiences of the identity provider server.
- Avoid trailing whitespace in the `issuer` string.

### Key validation error, Digest mismatch or Fingerprint mismatch

These errors all come from a similar place, the SAML certificate. SAML requests
must be validated using either a fingerprint, a certificate, or a validator.

For this requirement, be sure to take the following into account:

- If a fingerprint is used, it must be the SHA1 fingerprint
- If no certificate is provided in the settings, a fingerprint or fingerprint
  validator needs to be provided and the response from the server must contain
  a certificate (`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`)
- If a certificate is provided in the settings, it is no longer necessary for
  the request to contain one. In this case the fingerprint or fingerprint
  validators are optional

If none of the above described scenarios is valid, the request
fails with one of the mentioned errors.

### Missing claims, or `Email can't be blank` errors

The identity provider server needs to pass certain information in order for GitLab to either
create an account, or match the login information to an existing account. `email`
is the minimum amount of information that needs to be passed. If the identity provider server
is not providing this information, all SAML requests fail.

Make sure this information is provided.

Another issue that can result in this error is when the correct information is being sent by
the identity provider, but the attributes don't match the names in the OmniAuth `info` hash. In this case,
you must set `attribute_statements` in the SAML configuration to
[map the attribute names in your SAML Response to the corresponding OmniAuth `info` hash names](../../../integration/saml.md#attribute_statements).

## User sign in banner error messages

### Message: "SAML authentication failed: Extern UID has already been taken"

This error suggests you are signed in as a GitLab user but have already linked your SAML identity to a different GitLab user. Sign out and then try to sign in again using SAML, which should log you into GitLab with the linked user account.

If you do not wish to use that GitLab user with the SAML login, you can [unlink the GitLab account from the SAML app](index.md#unlinking-accounts).

### Message: "SAML authentication failed: User has already been taken"

The user that you're signed in with already has SAML linked to a different identity, or the NameID value has changed.
Here are possible causes and solutions:

| Cause                                                                                          | Solution                                                                                                                                                                   |
| ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| You've tried to link multiple SAML identities to the same user, for a given identity provider. | Change the identity that you sign in with. To do so, [unlink the previous SAML identity](index.md#unlinking-accounts) from this GitLab account before attempting to sign in again. |
| The NameID changes every time the user requests SSO identification | [Check the NameID](#verifying-nameid) is not set with `Transient` format, or the NameID is not changing on subsequent requests.|

### Message: "SAML authentication failed: Email has already been taken"

| Cause                                                                                                                                    | Solution                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| When a user account with the email address already exists in GitLab, but the user does not have the SAML identity tied to their account. | The user needs to [link their account](index.md#user-access-and-management). |

User accounts are created in one of the following ways:

- User registration
- Sign in through OAuth
- Sign in through SAML
- SCIM provisioning

### Message: "SAML authentication failed: Extern UID has already been taken, User has already been taken"

Getting both of these errors at the same time suggests the NameID capitalization provided by the identity provider didn't exactly match the previous value for that user.

This can be prevented by configuring the NameID to return a consistent value. Fixing this for an individual user involves changing the identifier for the user. For GitLab.com, the user needs to [unlink their SAML from the GitLab account](index.md#unlinking-accounts).

### Message: "Request to link SAML account must be authorized"

Ensure that the user who is trying to link their GitLab account has been added as a user within the identity provider's SAML app.

Alternatively, the SAML response may be missing the `InResponseTo` attribute in the
`samlp:Response` tag, which is [expected by the SAML gem](https://github.com/onelogin/ruby-saml/blob/9f710c5028b069bfab4b9e2b66891e0549765af5/lib/onelogin/ruby-saml/response.rb#L307-L316).
The identity provider administrator should ensure that the login is
initiated by the service provider and not only the identity provider.

### Message: "Sign in to GitLab to connect your organization's account" **(PREMIUM SAAS)**

A user can see this message when they are trying to [manually link SAML to their existing GitLab.com account](index.md#linking-saml-to-your-existing-gitlabcom-account).

To resolve this problem, the user should check they are using the correct GitLab password to log in. The user first needs
to [reset their password](https://gitlab.com/users/password/new) if both:

- The account was provisioned by SCIM.
- They are signing in with username and password for the first time.

## Other user sign in issues

### Verifying NameID

In troubleshooting, any authenticated user can use the API to verify the NameID GitLab already has linked to the user by visiting [`https://gitlab.com/api/v4/user`](https://gitlab.com/api/v4/user) and checking the `extern_uid` under identities.

For self-managed, administrators can use the [users API](../../../api/users.md) to see the same information.

When using SAML for groups, group members of a role with the appropriate permissions can make use of the [members API](../../../api/members.md) to view group SAML identity information for members of the group.

This can then be compared to the NameID being sent by the identity provider by decoding the message with a [SAML debugging tool](#saml-debugging-tools). We require that these match in order to identify users.

### Stuck in a login "loop"

Ensure that the **GitLab single sign-on URL** (for GitLab.com) or the instance URL (for self-managed) has been configured as "Login URL" (or similarly named field) in the identity provider's SAML app.

For GitLab.com, alternatively, when users need to [link SAML to their existing GitLab.com account](index.md#linking-saml-to-your-existing-gitlabcom-account), provide the **GitLab single sign-on URL** and instruct users not to use the SAML app on first sign in.

### Users receive a 404 **(PREMIUM SAAS)**

Because SAML SSO for groups is a paid feature, your subscription expiring can result in a `404` error when you're signing in using SAML SSO on GitLab.com.
If all users are receiving a `404` when attempting to log in using SAML, confirm
[there is an active subscription](../../../subscriptions/gitlab_com/index.md#view-your-gitlab-saas-subscription) being used in this SAML SSO namespace.

If you receive a `404` during setup when using "verify configuration", make sure you have used the correct
[SHA-1 generated fingerprint](../../../integration/saml.md#notes-on-configuring-your-identity-provider).

If a user is trying to sign in for the first time and the GitLab single sign-on URL has not [been configured](index.md#configure-your-identity-provider), they may see a 404.
As outlined in the [user access section](index.md#linking-saml-to-your-existing-gitlabcom-account), a group Owner needs to provide the URL to users.

### 500 error after login **(FREE SELF)**

If you see a "500 error" in GitLab when you are redirected back from the SAML
sign-in page, this could indicate that:

- GitLab couldn't get the email address for the SAML user. Ensure the identity provider provides a claim containing the user's
  email address using the claim name `email` or `mail`.
- The certificate set your `gitlab.rb` file for `identity provider_cert_fingerprint` or `identity provider_cert` file is incorrect.
- Your `gitlab.rb` file is set to enable `identity provider_cert_fingerprint`, and `identity provider_cert` is being provided, or the reverse.

### 422 error after login **(FREE SELF)**

If you see a "422 error" in GitLab when you are redirected from the SAML
sign-in page, you might have an incorrectly configured Assertion Consumer
Service (ACS) URL on the identity provider.

Make sure the ACS URL points to `https://gitlab.example.com/users/auth/saml/callback`, where
`gitlab.example.com` is the URL of your GitLab instance.

If the ACS URL is correct, and you still have errors, review the other
Troubleshooting sections.

### User is blocked when signing in through SAML **(FREE SELF)**

The following are the most likely reasons that a user is blocked when signing in through SAML:

- In the configuration, `gitlab_rails['omniauth_block_auto_created_users'] = true` is set and this is the user's first time signing in.
- [`required_groups`](../../../integration/saml.md#required-groups) are configured but the user is not a member of one.

## Google workspace troubleshooting tips

The Google Workspace documentation on [SAML app error messages](https://support.google.com/a/answer/6301076?hl=en) is helpful for debugging if you are seeing an error from Google while signing in.
Pay particular attention to the following 403 errors:

- `app_not_configured`
- `app_not_configured_for_user`
