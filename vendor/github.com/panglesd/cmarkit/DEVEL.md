
A few development tips.

# Benchmark parse to HTML rendering

```sh
time cmark --unsafe /file/to/md > /dev/null
time $(b0 --path -- bench --unsafe /file/to/md) > /dev/null
```

# Expectation tests

To add a new test, add an `.md` test in `test/expect`, run the tests
and add the new generated files to the repo.

```sh
b0 -- expect
b0 -- expect --help 
```

# Specification tests

To run the specification test use:

```sh
b0 -- test_spec             # All examples
b0 -- test_spec 1-10 34 56  # Specific examples
```

To test the CommonMark renderer on the specification tests use: 

```sh
b0 -- trip_spec             # All examples
b0 -- trip_spec 1-10 32 56  # Specific examples
b0 -- trip_spec --show-diff # Show correct render diffs (if applicable)
```

Given a source a *correct* render yields the same HTML and it *round
trips* if the source is byte-for-byte equivalent. Using `--show-diff`
on an example that does not round trip shows the reason and the diff.

The tests are also run on parses without layout preservation to check
they are correct.

# Pathological tests 

The [pathological tests][p] of `cmark` have been ported to
[`test/pathological.ml`]. You can run them on any executable that
reads CommonMark on standard input and writes HTML rendering on
standard output.

```sh
b0 -- pathological -- cmark
b0 -u cmarkit -- pathological -- $(b0 --path -- cmarkit html)
b0 -- pathological --help
b0 -- pathological -d /tmp/ #   Dump tests and expectations
```

[p]: https://github.com/commonmark/cmark/blob/master/test/pathological_tests.py
[`test/pathological.ml`]: src/cmarkit.ml

# Specification update

If there's a specification version update. The `commonmark_version`
variable must be updated in both in [`B0.ml`] and in [`src/cmarkit.ml`].
A `s/old_version/new_version/g` should be performed on `.mli` files.

The repository has the CommonMark specification test file in
[`test/spec.json`].

To update it invoke:

```sh
b0 -- update_spec_tests
```

[`test/spec.json`]: test/spec.json
[`src/cmarkit.ml`]: src/cmarkit.ml
[`B0.ml`]: B0.ml

# Unicode data update

The library contains Unicode data generated in the file
[`src/cmarkit_data_uchar.ml`]

To update it invoke:

```sh
opem install uucp
b0 -- update_unicode_data
```

[`src/cmarkit_data_uchar.ml`]: src/cmarkit_data_uchar.ml
