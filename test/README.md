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

First, from the `screenshot-based` folder, install the dependencies and the browsers:

```shell
npm ci
npx playwright install --with-deps chromium firefox
```

Then, generate the HTML files of all tests with dune:

```shell
dune build --profile release
```

Each test folder has a `dune` file that compiles its `.slp` and `.md` entries
to HTML files next to them, with the same base name. When adding an entry to a
`run.json`, add the corresponding rule.

Then, from the `screenshot-based` folder, run the tests with:

```shell
npx playwright test
```

To run only some tests, use `-g` with a regular expression matching the test
titles, which have the form `<folder>/<entry> › step <N>`, and optionally
`--project` to select a browser:

```shell
# One test folder
npx playwright test -g 'math/'

# One step of one entry, in one browser
npx playwright test -g 'bobkonf.html.*step 5$' --project=chromium
```

Use `.*` rather than the `›` separator, and end with `$` so that `step 5` does
not also match `step 50`. Add `--list` to see the selected tests without
running them, and `--update-snapshots` to accept the current rendering of the
selected tests.

To see the screenshots of failed tests, including the ones of the CI (download
the `playwright-report` artifact of the workflow run), use:

```shell
npx playwright show-report <report folder>
```
