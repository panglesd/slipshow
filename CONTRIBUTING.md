# Contributing

## Releasing

In order to release a new version, do:

```
$ $editor CHANGELOG.md      # Update the "Unreleased" to the new version
$ yarn build-and-pack       # Build, and create an archive for some reason
$ npm version patch         # Or minor or major, let's dream!
$ npm publish               # Publishing
$ git push
$ # and push tags!
```

