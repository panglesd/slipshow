# Contributing

## Releasing

In order to release a new version, do:

```
$ $editor CHANGELOG.md      # Update the "Unreleased" to the new version
$ dune build
        --profile=with-bundle
        --auto-promote
        @data-files
$ dune build --profile=release
$ yarn build-and-pack       # Build, and create an archive for some reason
                            # (so that people can download it and start without having npm)
$ npm version patch         # Or minor or major, let's dream!
$ npm publish               # Publishing
$ git push
$ # and push tags!
```

