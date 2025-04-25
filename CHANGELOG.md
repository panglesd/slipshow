# Changelog

## [v0.2.0] Friday 11th April, 2025. Lyon.

### CLI

- Split commands in groups (#112). Examples:
  - `slipshow file.md` becomes `slipshow compile file.md`
  - `slipshow --serve file.md` becomes `slipshow serve file.md`
  - `slipshow --markdown-output file.md` becomes `slipshow markdown file.md`
- Add a `--theme` argument and a command to list the themes: `slipshow themes
  list` (#109)

### Compile

- Fix file watching issues by vendoring a (modified) irmin-watcher, and watching
  all files the presentation depends on (images, themes, ...) (#113)

### Engine

- Allow to focus on multiple elements. Zooms as much as possible so everything
  is visible, and center. Backward compatible, focusing on a single
  element. (#103)
- Pass all actions to slip-scripts, accesible via the `slip` object. (#104)
- Introduce `slip.onUndo`, `slip.setProp` and `slip.state`. (#97)
- Improve mobile support, with buttons to navigate and open the table of content
  (#106)
- Add `scroll` action to scroll up or down, if needed (#107)

### Themes

- Add the "vanier" theme from the pre-OCaml era (#109)

## [v0.1.1] Thursday 13th march, 2025. Lyon.

Quick release mostly to allow publishing on opam!

- Vendor modified Brr, instead of pinning.
- Build released binaries in release mode, without QEMU.
- Fix `-dirty` suffix on `slipshow --version`.

## [v0.1.0] Friday 7th March, 2025. Lyon.

> [!NOTE]
> TLDR:
> - Engine rewritten in OCaml
>   - Fewer bugs when navigating back
>   - Stronger foundation (eg, for subslips)
>   - Custom scripts requires minor adjustments
>   - Breaking change in subslip HTML
> - Drawing now in SVG
>   - No more zoom issues
>   - Erasing works "per-stroke"
> - Revamped table of content
>   - Now based on title structure rather than subslips
> - New `--markdown-output` flag for converting to GFM
> - Parser bugfixes
> - License change: Now GPLv3 (previously MIT)
> - npm distribution discontinued.
> - Special thanks to NLNet for their [sponsorship](https://nlnet.nl/project/Slipshow/)!

Dear readers,

I am thrilled to announce the 0.1 release of Slipshow, the slip-based
presentation tool!

This is a _major_ minor release. While versions `0.0.1` to `0.0.33` have served well
to experiment, this release marks a fresh start, aimed at being a solid
foundation for a project with a clear direction. A huge thank you to NLNet for
[sponsoring](https://nlnet.nl/project/Slipshow/) this milestone!

So, what is new? Quite a lot, the main change being that the engine has been
_fully rewritten_.

### The engine

Started as a single file javascript project, the old engine evolved presentation
by presentation -- leading to numerous bugs, maintenance challenge or
extensibility issue. (In other word, I did all I could not to touch it despite
all the bugs)

This release introduces a complete rewrite of the engine in OCaml, with new
design choices that improve reliability and expandability. Let's go over the key
benefits and breaking changes.

#### Navigating Forward... and Backward

One of the greatest weakness of the old engine was handling backward
navigation. Since it started as a simple "script scheduler", going back wasn't straightforward. The workaround involved taking a snapshot
of... everything (the DOM, the state, ...), to be able to go back in time.

This had many bugs, in animations (such as the "focus" action), and in its
iteraction with other features (such as drawing).

So, what is new in this engine? The engine now records an undo function for each
step of the presentation.
While this may not sound much, it is a ton better in terms of development. It's
a much stronger foundation to build new features from. It's also much more
efficient for long presentations.

In most cases, your old presentations will work without modification in the new
engine. However, there is one case where it needs modification: when you include
the execution of a custom script in your presentation. In this case, you need to
return the function undo to undo the executed step: see the
[documentation](https://slipshow.readthedocs.io/en/stable/syntax.html#custom-scripts)!
(This is not ideal and better solutions are being experimented)

#### Writing

Previously, live annotations used the excellent
[atrament](https://github.com/jakubfiala/atrament) library. While great in many
cases, its bitmap-based approach caused blurriness when zooming.

This release introduces a custom SVG-based annotation system, which eliminates
zoom issues. Another change: erasing now works stroke-by-stroke instead of
pixel-by-pixel.

#### Table of content

The old table of contents was based on the slip structure, which didn’t work
well for presentations that primarily used a single slip (as is often the case
with compiled presentations).

The new sidebar-style table of contents is now generated from headers, making it
more intuitive and aligned with the presentation’s structure—resulting in a much
smoother navigation experience!

#### Breaking change: Subslips

The HTML structure for subslips has evolved, in particuler to avoid having to
provide the scale of your subslips.

Support for subslip in the new engine is not mature and will be announced in the
next release, but bear in mind that if your presentation relies on them, you
might want to wait a bit before migrating to the new engine!

### Compiler

While this release focuses on the engine, the compiler has also seen improvements, including bug fixes (particularly in the parser) and a new feature:

#### `--markdown-output` for markdown exports

If you want to print your presentation or host it as a static webpage, the
default format can be cluttered with annotations. The new `--markdown-output` flag
lets you generate a clean, GitHub Flavored Markdown (GFM) file without
annotations.

### Other

Beyond technical improvements, there are some important project-wide updates:

- License Change: The project has transitioned from MIT to GPLv3, aligning
  better with its values.
- npm Distribution Discontinued: Maintaining an npm package added unnecessary
  complexity with minimal benefit. Please use binary releases — or better yet,
  contribute to getting Slipshow packaged in distributions!

### Looking ahead

Several improvements did not make it in this release, but are already quite
advanced. So here is a little peek into the future:

- Subslip returns! After having been a little left over since the introduction
  of the compiler, are coming back, with a better though implementation!
- Full mobile support is on its way! It has already been improved, but is not
  yet mature enough to be announced in this release.

### Conclusion

Looking forward to your bug reports!


## [v0.0.33] September 13th, 2024.

### Fixed

- Fixed `--serve` sometimes not working by using long-polling instead of
  websockets.
- Fixed `--serve` not working on MacOS (#65, @patricoferris)

## [v0.0.32] May 27th, 2024.

### Fixed

- Use 127.0.0.1 to avoid problem with `localhost` in musl-based compilation
- Fix log message in `--serve`
- Fix `slip-script` attributes
- Fixed file watching for emacs and vim
- Fixed flickering on `--serve` when saving, using slipshow preview
- Vendor forked cmarkit

## [v0.0.31] February 5th, 2024.

### Added

- Added the "Space" key to advance in the presentation

### Fixed

- Fix sketchpad being white when going backward
- Prevent going out of bound in the presentation
- Fix missing fonts for math
- Fix spacing after "Proof"
- Take babel.json into account for the engine

## [v0.0.30] January 9th, 2024.

### Fixed

- Fix sketchpad disappearing when going backward

## [v0.0.29] December 1st, 2023.

## Fixed

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
