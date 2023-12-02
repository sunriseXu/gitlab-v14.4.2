---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Push rules **(PREMIUM)**

Push rules are [pre-receive Git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) you
can enable in a user-friendly interface. Push rules give you more control over what
can and can't be pushed to your repository. While GitLab offers
[protected branches](../protected_branches.md), you may need more specific rules, such as:

- Evaluating the contents of a commit.
- Confirming commit messages match expected formats.
- Enforcing branch name rules.
- Evaluating the details of files.
- Preventing Git tag removal.

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions
in push rules. You can test them at the [regex101 regex tester](https://regex101.com/).

For custom push rules use [server hooks](../../../administration/server_hooks.md).

## Enable global push rules

You can create push rules for all new projects to inherit, but they can be overridden
at the project level or the [group level](../../group/access_and_permissions.md#group-push-rules).
All projects created after you configure global push rules inherit this
configuration. However, each existing project must be updated manually, using the
process described in [Override global push rules per project](#override-global-push-rules-per-project).

Prerequisite:

- You must be an administrator.

To create global push rules:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Push Rules**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Override global push rules per project

The push rule of an individual project overrides the global push rule.
To override global push rules for a specific project, or to update the rules
for an existing project to match new global push rules:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Verify users

Use these rules to validate users who make commits.

- **Reject unverified users**: Users must have a [confirmed email address](../../../security/user_email_confirmation.md).
- **Check whether the commit author is a GitLab user**: The commit author and committer must have an email address that's been verified by GitLab.
- **Commit author's email**: Both the author's and committer's email addresses must match the regular expression.
  To allow any email address, leave empty.

## Validate commit messages

Use these rules for your commit messages.

- **Require expression in commit messages**: Messages must match the
  expression. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled by using `(?-m)`.

  For example, if every commit should reference a Jira issue
  (like `Refactored css. Fixes JIRA-123.`), the regular expression would be
  `JIRA\-\d+`.
- **Reject expression in commit messages**: Commit messages must not match
  the expression. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled by using `(?-m)`.

## Validate branch names

To validate your branch names, enter a regular expression for **Branch name**.
To allow any branch name, leave empty. Your [default branch](branches/default.md)
is always allowed. Certain formats of branch names are restricted by default for
security purposes. Names with 40 hexadecimal characters, similar to Git commit hashes,
are prohibited.

Some validation examples:

- Branches must start with `JIRA-`.

  ```plaintext
  `^JIRA-`
  ```

- Branches must end with `-JIRA`.

  ```plaintext
  `-JIRA$`
  ```

- Branches must be between `4` and `15` characters long,
  accepting only lowercase letters, numbers and dashes.

  ```plaintext
  `^[a-z0-9\\-]{4,15}$`
  ```

## Prevent unintended consequences

Use these rules to prevent unintended consequences.

- **Reject unsigned commits**: Commit must be signed through [GPG](gpg_signed_commits/index.md). This rule
  can block some legitimate commits [created in the Web IDE](#reject-unsigned-commits-push-rule-disables-web-ide),
  and allow [unsigned commits created in the GitLab UI](#unsigned-commits-created-in-the-gitlab-ui).
- **Do not allow users to remove Git tags with `git push`**: Users cannot use `git push` to remove Git tags.
  Users can still delete tags in the UI.

## Validate files

Use these rules to validate files contained in the commit.

- **Prevent pushing secret files**: Files must not contain [secrets](#prevent-pushing-secrets-to-the-repository).
- **Prohibited file names**: Files that do not exist in the repository
  must not match the regular expression. To allow all file names, leave empty. See [common examples](#prohibit-files-by-name).
- **Maximum file size**: Added or updated files must not exceed this
  file size (in MB). To allow files of any size, set to `0`. Files tracked by Git LFS are exempted.

### Prevent pushing secrets to the repository

> Moved to GitLab Premium in 13.9.

Never commit secrets, such as credential files and SSH private keys, to a version control
system. In GitLab, you can use a predefined list of files to block those files from a
repository. Merge requests that contain a file that matches the list are blocked.
This push rule does not restrict files already committed to the repository.
You must update the configuration of existing projects to use the rule, using the
process described in [Override global push rules per project](#override-global-push-rules-per-project).

Files blocked by this rule are listed below. For a complete list of criteria, refer to
[`files_denylist.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml).

- AWS CLI credential blobs:

  - `.aws/credentials`
  - `aws/credentials`
  - `homefolder/aws/credentials`

- Private RSA SSH keys:

  - `/ssh/id_rsa`
  - `/.ssh/personal_rsa`
  - `/config/server_rsa`
  - `id_rsa`
  - `.id_rsa`

- Private DSA SSH keys:

  - `/ssh/id_dsa`
  - `/.ssh/personal_dsa`
  - `/config/server_dsa`
  - `id_dsa`
  - `.id_dsa`

- Private ED25519 SSH keys:

  - `/ssh/id_ed25519`
  - `/.ssh/personal_ed25519`
  - `/config/server_ed25519`
  - `id_ed25519`
  - `.id_ed25519`

- Private ECDSA SSH keys:

  - `/ssh/id_ecdsa`
  - `/.ssh/personal_ecdsa`
  - `/config/server_ecdsa`
  - `id_ecdsa`
  - `.id_ecdsa`

- Private ECDSA_SK SSH keys (GitLab 14.8 and later):

  - `/ssh/id_ecdsa_sk`
  - `/.ssh/personal_ecdsa_sk`
  - `/config/server_ecdsa_sk`
  - `id_ecdsa_sk`
  - `.id_ecdsa_sk`

- Private ED25519_SK SSH keys (GitLab 14.8 and later):

  - `/ssh/id_ed25519_sk`
  - `/.ssh/personal_ed25519_sk`
  - `/config/server_ed25519_sk`
  - `id_ed25519_sk`
  - `.id_ed25519_sk`

- Any files ending with these suffixes:

  - `*.pem`
  - `*.key`
  - `*.history`
  - `*_history`

### Prohibit files by name

> Moved to GitLab Premium in 13.9.

In Git, filenames include both the file's name, and all directories preceding the name.
When you `git push`, each filename in the push is compared to the regular expression
in **Prohibited file names**.

The regular expression in your **Prohibited file names** push rule can contain multiple,
independent matches to exclude. You can match file names broadly to any location in
your repository, or restrict only in certain locations. Filename matches can also
be partial, and exclude file types by extension.

These examples use regex (regular expressions) string boundary characters to match
the beginning of a string (`^`), and its end (`$`). They also include instances
where either the directory path or the filename can include `.` or `/`. Both of
these special regex characters must be escaped with a backslash `\\` if you want
to use them as normal characters in a match condition.

- **Prevent pushing `.exe` files to any location in the repository** - This regex
  matches any filename that contains `.exe` at the end:

  ```plaintext
  \.exe$
  ```

- **Prevent pushing a specific configuration file in the repository root**

  ```plaintext
  ^config\.yml$
  ```

- **Prevent pushing a specific configuration file in a known directory**

  ```plaintext
  ^directory-name\/config\.yml$
  ```

- **Prevent pushing a specific file to any location in the repository** - This example tests
  for any file named `install.exe`. The parenthesized expression `(^|\/)` matches either
  a file following a directory separator, or a file in the root directory of the repository:

  ```plaintext
  (^|\/)install\.exe$
  ```

- **Combine all previous expressions into one expression** - The preceding expressions rely
  on the end-of-string character `$`. We can move that part of each expression to the
  end of the grouped collection of match conditions, where it is appended to all matches:

  ```plaintext
  (\.exe|^config\.yml|^directory-name\/config\.yml|(^|\/)install\.exe)$
  ```

## Related topics

- [Server hooks](../../../administration/server_hooks.md), to create complex custom push rules
- [Signing commits with GPG](gpg_signed_commits/index.md)
- [Protected branches](../protected_branches.md)

## Troubleshooting

### Reject unsigned commits push rule disables Web IDE

In GitLab 13.10, if a project has the **Reject unsigned commits** push rule, the user cannot
create commits through the GitLab Web IDE.

To allow committing through the Web IDE on a project with this push rule, a GitLab administrator
must disable the feature flag `reject_unsigned_commits_by_gitlab`. [with a flag](../../../administration/feature_flags.md)

```ruby
Feature.disable(:reject_unsigned_commits_by_gitlab)
```

### Unsigned commits created in the GitLab UI

The **Reject unsigned commits** push rule ignores commits that are authenticated
and created by GitLab (either through the UI or API). When this push rule is
enabled, unsigned commits may still appear in the commit history if a commit was
created in GitLab itself. As expected, commits created outside GitLab and
pushed to the repository are rejected. For more information about this issue,
read [issue #19185](https://gitlab.com/gitlab-org/gitlab/-/issues/19185).
