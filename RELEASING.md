# Releasing to pub.dev

Use Python 3.9 or later and the Dart bundled with Flutter 3.50.1, the SDK used by CI.
The release tool packages only files committed at `HEAD`. It resolves hosted
dependencies independently of the local workspace members. Run it from the commit you intend to release.

```sh
python3 tool/pub_release.py co_faker
```

This runs `dart pub publish --dry-run`. Each package folder has a README,
changelog and license. The repository root and the full demo apps under
`example/` are kept for development and GitHub Pages. The Flutter archives
include standalone examples where the full demo relies on the monorepo.

Run `python3 tool/pub_release.py --check-all` to check every release entry and
run the dry runs whose dependencies are on pub.dev. Pull request CI uses the
same command. Packages waiting for their first sibling or CoUI release are
listed separately. Use the package-specific dry run before uploading it.

## First releases

pub.dev limits each uploader to four new packages per rolling two minutes
and twelve per rolling day. Check for a version on pub.dev before retrying
an interrupted batch. Review the [registry limits](https://github.com/dart-lang/pub-dev/blob/a6b664df3b741107b55f43e96df7811c9c7abe09/app/config/dartlang-pub.yaml#L60-L64).

Publish in this order. Packages in the same row can be published independently
once their prerequisites appear on pub.dev.

| Order | Packages | Prerequisites |
| --- | --- | --- |
| 1 | `co_arc`, `co_bdd`, `co_demo_prefs`, `co_faker`, `co_golden`, `co_site_metadata`, `co_storage`, `co_xterm2`, `co_xterm3`, `open_board`, `open_epub_engine`, `open_note` | Hosted dependencies already available |
| 2 | `co_demo_world` | `co_demo_prefs ^1.0.1`, `co_faker ^0.13.1` |
| 2 | `open_epub` | `open_epub_engine >=1.1.0 <1.2.0` |
| 3 | `co_golden_gallery` | `coui_web ^0.192.0` |

The Flutter examples resolve `co_example_ui` from the workspace. Its
`publish_to: none` keeps it out of the release manifest. The gallery uses
stable `coui_web` from pub.dev.

The terminal forks use the distinct pub.dev names `co_xterm2` (MIT) and
`co_xterm3` (AGPL-3.0-or-later). Existing Git tags use the original package
names. When moving from those tags, update the dependency key and the `package:`
prefix in imports.

For each first release, complete the dry run, then run the same command with
`--publish` using the Google account that will own the upload. Pub will prompt
for confirmation. Wait for the package and version to appear on pub.dev before
running the dry run for its dependents.

```sh
python3 tool/pub_release.py co_faker --publish
```

See [Dart's publishing guide](https://dart.dev/tools/pub/publishing) for uploader
access and transferring a package to a verified publisher.

## Later releases

1. On each package's pub.dev **Admin → Automated publishing** page, allow
   GitHub Actions from `coco-de/co-package` with `<package>-v{{version}}`.
   For example, set `co_xterm2-v{{version}}` for `co_xterm2`. If you require a
   GitHub environment there, use `pub.dev`. The workflow uses OIDC.
2. Merge the release-please PR. To have release-please's tags trigger the
   publish workflow, configure `RELEASE_PLEASE_TOKEN` with a repository-scoped
   PAT that has Contents and Pull requests write access. A GitHub App can also
   supply a short-lived token if the release workflow generates it in the job.
3. The publish workflow checks that the tag matches the committed pubspec. If
   the same commit also tags a sibling dependency, it waits for that version on
   pub.dev before publishing the dependent.

If a release moves a sibling package beyond a dependent's supported range,
update the dependent's pubspec and run its tests in the same release PR.

With GitHub's default Actions token, release-please creates the GitHub Release
and tag. For such tags, check out the tag and run the manual publish command.
You can also push a new release tag from a maintainer checkout after enabling
OIDC on pub.dev. Push tags individually to trigger a run for each package.

See [pub.dev automated publishing](https://dart.dev/tools/pub/automated-publishing)
and [GitHub Actions triggering rules](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow).
