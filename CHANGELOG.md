# Changelog

## [Unreleased]

## Fixed

- Use 127.0.0.1 to avoid problem with `localhost` in musl-based compilation
- Fix log message in `--serve`
- Fix `slip-script` attributes
- Fixed file watching for emacs and vim
- Fixed flickering on `--serve` when saving, using slipshow preview
- Vendor forked cmarkit

## [v0.0.31] February 5th, 2024.

### Added

- Added the "Space" key to advance in the presentation

## Fixed

- Fix sketchpad being white when going backward
- Prevent going out of bound in the presentation
- Fix missing fonts for math
- Fix spacing after "Proof"
- Take babel.json into account for the engine

## [v0.0.30] January 9th, 2024.

## Fixed

- Fix sketchpad disappearing when going backward

## [v0.0.29] December 1st, 2023.

### Fixed

- Use `release` mode for compiler, to save space

## [v0.0.28] December 1st, 2023.

### Added

- Compiler from a superset of markdown to a standalone html page

### Fixed

- Better handling of initialization and synchro with parent frame

## [v0.0.27] November 28th, 2023.

### Added

- Now uses `#` anchors to directly get to a state. Also, send that to a parent
  window, if any, and listen for messages from the parent window for state to
  jump into.

## [v0.0.25] and [v0.0.26] November 20th, 2023.

### Added

- Added `emph-at-unpause` and `unemph-at-unpause` attributes.

### Fixed

- Upgraded dependencies
