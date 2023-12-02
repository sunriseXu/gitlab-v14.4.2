---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

<!---
  The clean_redirects Rake task in the gitlab-docs repository manually
  excludes this file. If the line containing remove_date is moved to a new
  document, update the Rake task with the new location.

  https://gitlab.com/gitlab-org/gitlab-docs/-/blob/1979f985708d64558bb487fbe9ed5273729c01b7/Rakefile#L306
--->

# Redirects in GitLab documentation

When you move, rename, or delete a page, you must add a redirect. Redirects reduce
how often users get 404s when they visit the documentation site from out-of-date links.

Add a redirect to ensure:

- Users see the new page and can update or delete their bookmark.
- External sites can update their links, especially sites that have automation that
  checks for redirected links.
- The documentation site global navigation does not link to a missing page.

  The links in the global navigation are already tested in the `gitlab-docs` project.
  If the redirect is missing, the `gitlab-docs` project's `main` branch might break.

Be sure to assign a technical writer to any merge request that moves, renames, or deletes a page.
Technical Writers can help with any questions and can review your change.

## Types of redirects

There are two types of redirects:

- [Redirects added into the documentation files themselves](#redirect-to-a-page-that-already-exists), for users who
  view the docs in `/help` on self-managed instances. For example,
  [`/help` on GitLab.com](https://gitlab.com/help). These must be added in the same
  MR that renames or moves a doc. Redirects to internal pages expire after three months
  and redirects to external pages (starting with `https:`) expire after a year.
- [GitLab Pages redirects](../../user/project/pages/redirects.md), which are added
  automatically after redirect files expire. They must not be manually added by
  contributors and expire after nine months. Redirects pointing to external sites
  are not added to the GitLab Pages redirects.

Expired redirect files are removed from the documentation projects by the
[`clean_redirects` Rake task](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/raketasks.md#clean-up-redirects),
as part of the Technical Writing team's [monthly tasks](https://gitlab.com/gitlab-org/technical-writing/-/blob/main/.gitlab/issue_templates/tw-monthly-tasks.md).

## Redirect to a page that already exists

To redirect a page to another page in the same repository:

1. In the Markdown file that you want to direct to a new location:

   - Delete all of the content.
   - Add this content:

     ```markdown
     ---
     redirect_to: '../newpath/to/file/index.md'
     remove_date: 'YYYY-MM-DD'
     ---

     This document was moved to [another location](../path/to/file/index.md).

     <!-- This redirect file can be deleted after <YYYY-MM-DD>. -->
     <!-- Redirects that point to other docs in the same project expire in three months. -->
     <!-- Redirects that point to docs in a different project or site (for example, link is not relative and starts with `https:`) expire in one year. -->
     <!-- Before deletion, see: https://docs.gitlab.com/ee/development/documentation/redirects.html -->
     ```

   - Replace both instances of `../newpath/to/file/index.md` with the new file path.
   - Replace both instances of `YYYY-MM-DD` with the expiration date, as explained in the template.

1. If the page has Disqus comments, follow [the steps for pages with Disqus comments](#redirections-for-pages-with-disqus-comments).
1. If the page had images that aren't used on any other pages, delete them.

After your changes are committed, search for and update all links that point to the old file:

- In <https://gitlab.com/gitlab-com/www-gitlab-com>, search for full URLs:

  ```shell
  grep -r "docs.gitlab.com/ee/path/to/file.html" .
  ```

- In <https://gitlab.com/gitlab-org/gitlab-docs/-/tree/master/content/_data>,
  search the navigation bar configuration files for the path with `.html`:

  ```shell
  grep -r "path/to/file.html" .
   ```

- In any of the four internal projects, search for links in the docs
  and codebase. Search for all variations, including full URL and just the path.
  For example, go to the root directory of the `gitlab` project and run:

  ```shell
  grep -r "docs.gitlab.com/ee/path/to/file.html" .
  grep -r "path/to/file.html" .
  grep -r "path/to/file.md" .
  grep -r "path/to/file" .
  ```

  You might need to try variations of relative links, such as `../path/to/file` or
  `../file` to find every case.

### Move a file's location

If you want to move a file from one location to another, you do not move it.
Instead, you duplicate the file, and add the redirect code to the old file.

1. Create the new file.
1. Copy the contents of the old file to the new one.
1. In the old file, delete all the content.
1. In the old file, add the redirect code and follow the rest of the steps in
   the [Redirect to a page that already exists](#redirect-to-a-page-that-already-exists) topic.

## Use code to add a redirect

If you prefer to use a script to create the redirect:

Add the redirect code to the old documentation file by running the
following Rake task. The first argument is the path of the old file,
and the second argument is the path of the new file:

- To redirect to a page in the same project, use relative paths and
  the `.md` extension. Both old and new paths start from the same location.
  In the following example, both paths are relative to `doc/`:

  ```shell
  bundle exec rake "gitlab:docs:redirect[doc/user/search/old_file.md, doc/api/new_file.md]"
  ```

- To redirect to a page in a different project or site, use the full URL (with `https://`) :

  ```shell
  bundle exec rake "gitlab:docs:redirect[doc/user/search/old_file.md, https://example.com]"
  ```

- Alternatively, you can omit the arguments and be prompted to enter the values:

  ```shell
  bundle exec rake gitlab:docs:redirect
  ```

## Redirecting a page created before the release

If you create a new page and then rename it before it's added to a release on the 18th:

Instead of following that procedure, ask a Technical Writer to manually add the redirect
to [`redirects.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/content/_data/redirects.yaml).

## Redirections for pages with Disqus comments

If the documentation page being relocated already has Disqus comments,
we need to preserve the Disqus thread.

Disqus uses an identifier per page, and for <https://docs.gitlab.com>, the page identifier
is configured to be the page URL. Therefore, when we change the document location,
we need to preserve the old URL as the same Disqus identifier.

To do that, add to the front matter the variable `disqus_identifier`,
using the old URL as value. For example, let's say we moved the document
available under `https://docs.gitlab.com/my-old-location/README.html` to a new location,
`https://docs.gitlab.com/my-new-location/index.html`.

Into the **new document** front matter, we add the following information. You must
include the filename in the `disqus_identifier` URL, even if it's `index.html` or `README.html`.

```yaml
---
disqus_identifier: 'https://docs.gitlab.com/my-old-location/README.html'
---
```
