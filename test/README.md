# Tests

There are two kinds of tests

## CLI tests

CLI tests take the form of [cram tests](https://dune.readthedocs.io/en/stable/tests.html#cram-tests)

Run them with:

```shell
dune test
```

## Browser tests

Browser tests take the form of screenshot tests, implemented using [playwright visual tests](https://playwright.dev/docs/test-snapshots).

Each test folder has a `dune` file that compiles its `.slp` and `.md` entries
to HTML files next to them, with the same base name. When adding an entry to a
`run.json`, add the corresponding rule.

Then, run the tests in [Playwright's Docker image](https://playwright.dev/docs/docker).
Browser rendering depends on the fonts and libraries of the host, so using the
same image everywhere ensures that the screenshots are the same locally and in
the CI. This requires Docker.

```shell
./playwright-docker.sh
```

The arguments of `playwright-docker.sh` are passed to `playwright test`. For
instance, to run only some tests, use `-g` with a regular expression matching
the test titles, which have the form `<folder>/<entry> › step <N>`, and
optionally `--project` to select a browser:

```shell
# One test folder
./playwright-docker.sh -g 'math/'

# One step of one entry, in one browser
./playwright-docker.sh -g 'bobkonf.html.*step 5$' --project=chromium
```

Use `.*` rather than the `›` separator, and end with `$` so that `step 5` does
not also match `step 50`. Add `--list` to see the selected tests without
running them, and `--update-snapshots` to accept the current rendering of the
selected tests. Screenshots generated outside of the Docker image may differ
slightly from the ones of the CI.

To see the screenshots of failed tests, including the ones of the CI (download
the `playwright-report` artifact of the workflow run), use:

```shell
npx playwright show-report <report folder>
```
