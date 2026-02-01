# Changelog

## Unreleased

### Added

- Support for syntax highlighting of all highlightjs-supported languages and
  themes (#200)

### Fix

- Fix impossibility to reopen speaker view after closing it on Firefox (#198,
  issue #194)
- Fix impossibility to open speaker view in serve mode (#198, issue #197)
- Fix links opening inside iframe (#198)

## [v0.8.1] Les gnomes voleurs de Slipshow (Tuesday 21th January, 2026)

### Fix

- Fix horrible mistake.

## [v0.8.0] Les gnomes voleurs de Slipshow (Tuesday 20th January, 2026)

### Features

- Add a "mirror mode" to the speaker view, which mirrors the entire screen you
  are sharing with the audience (#188)
- Add support for external files through CLI and frontmatter (#191)
- Add shortcut to delete or unselect selection in drawing editing (#192)
- Add a "Close editing panel" button when there are no strokes (#192)
- Default file names for drawing recording depend on their names (#192)
- Improve `-o` argument wrt directories (#190)
- Inline SVGs instead of adding them as images, allowing the use of classes and
  ids in SVGs (#190)
- Rework the docs! (#190)

### Fix

- Fix pauses time not updated after a rerecording (#192)
- Fix drawing editing shortcuts triggering even when focusing on a textarea
  (#192)
- Fix interaction between fields and drawing editing shortcuts (#192)
- Fix order of `clear` and `draw` action: the first comes first (#192)
- Use .woff2 for embedded fonts (#190)

## [v0.7.0] The Slipshow of Dorian Gray (Wednesday 26th November, 2025)

## Compiler

- Embed Liberation Sans fonts (and use them) (#150)
- Fix missing favicon (which was missing since speaker view) (#150)
- Fix changing step number from speaker note does not update serve mode state
  (#154)
- Fix blank lines considered as elements in carousel (#170)
- Allow to specify port in `slipshow serve` with `-p` or `--port` (#176)
- Fix link with no content in block raising a syntax error (#180)
- Remove support for Setext headings (#178)

## Engine

- Fix speaker note scrolling (#150)
- Fix script undos recovery when script execution fails (#150)
- Hide paused/unrevealed elems also for mouse (#150)
- Don't execute scripts when computing toc (#150)
- Mute medias in speaker view (#152)
- Use the [perfect-freehand](https://github.com/steveruizok/perfect-freehand)
  library to generate strokes. (#151)
- Fix order of execution of actions (`center` after `enter`) (#171)
- Fix pauses not being scoped in slides (#179)
- Fix exiting not where it should (#179)
- Fix `unfocus` behavior to match the docs (#179)
- Fix wrong position bug on custom dimensions (#182)
- Fix infinitely jiggling autoresizing
- Fix not being able to draw outside of inner presentation
- Fix permanent fast-moving bug

## [v0.6.0] The King's Slipshow (Monday 18th August, 2025)

### Engine

- Add a speaker view, opened with `s`. (#147)
- Fix `Z` and `X` not working (#147)
- On step change, move back to the position we left (#148)

### Language

- Add a `speaker-note` action. (#147)

## [v0.5.0] Plan 9 from External Files (Thursday 7th August, 2025)

### Compiler

- Add support for pdfs (#144)
- Add support for audios and videos (#139, #142)
- Fix `enter` action being added to blockquotes

### Language

- Add a carousel type and a `change-page` action (#144)
- Add a `play-media` action (#139, #142)

### Engine

- Fix compatibility of slipshow and editable content (#141)
- Fix scroll bar appearing in drawing toolbox (#143)

## [v0.4.1] (Wednesday 16th July, 2025)

### Engine

- Fix pauses hiding the UI

## [v0.4.0] The slides strike back (Wednesday 16th July, 2025)

### Compiler

- Fix `children:` not working sometimes (#135)
- Add `--toplevel-attributes` to control the attributes on the toplevel
  container (#137)

### Engine

- Render slide titles as slide titles (#137)

### Language

- Add arguments to actions (#135)
- Add frontmatter (#137)

### Internal

- Add compatibility with latest version of Cmdliner (#135)
- Fix `"` sometimes being present in Cmarkit, removing the need for ~~hacks~~
  workarounds. (#135)


## [v0.3.0] The return of the subslips (Friday 3rd July, 2025)

### Compiler

- Fix file watching issues by vendoring a (modified) irmin-watcher, and watching
  all files the presentation depends on (images, themes, ...) (#113)
- Adds a favicon to the presentation file (#115)
- Fix missing attributes on images (#117)
- Fix missing mime type on images that made svg undisplayable (#120)
- Fix detection of math inside inline attributes (#124)
- Add `--dimension` to specify the dimension of the presentation (#131)
- Add less boring name for versions (#132)

### Language

- Add `{include src="path/to/file.md"}` to include a file in another (#114)
- Allow `pause` to have a target (#118)
- Remove the need for `step` to execute actions (#118)
- Added support for subslips and slides (#118)
- Added pause blocks (#127)
- Use horizontal lines (`---`) to group blocks (#129)
- Pass attributes to children with `children:` (#130)
- Consistently remove the need for `-at-unpause` (#133)

### Engine

- Simplify table of content by removing preview (#118)
- Fix wrong computation of location (#118, #119)
- Improve zooming behaviour and performance (#121)
- Add PageUp and PageDown as navigation keys, adding support for pointers (#126)
- Do not act when control is pressed (#126)
- Fix wrong positioning on scaled slips (#128)

## [v0.2.0] Friday 11th April, 2025. Lyon.

### CLI

- Split commands in groups (#112). Examples:
  - `slipshow file.md` becomes `slipshow compile file.md`
  - `slipshow --serve file.md` becomes `slipshow serve file.md`
  - `slipshow --markdown-output file.md` becomes `slipshow markdown file.md`
- Add a `--theme` argument and a command to list the themes: `slipshow themes
  list` (#109)

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
