# Contributing

## Releasing

In order to release a new version, do:

```
$ yarn build-and-pack       # Build, and create an archive for some reason
$ $editor CHANGELOG.md      # Update the "Unreleased" to the new version
$ npm version patch         # Or minot or major, let's dream!
$ npm publish               # Publishing
```

