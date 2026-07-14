=============
 Frontmatter
=============

The *frontmatter* allows you to define metadata for the whole presentation. For every CLI option, there is a corresponding frontmatter option.

Within the input file, the frontmatter starts with a ``---``, and ends with the
next ``---``. Within this region, metadata is set using a key-value syntax, with ``:``
used as a separator. No quotes are needed, but no newlines are accepted within
the values. It's likely that Slipshow will switch to using yaml for the frontmatter at some point…

.. code-block:: markdown

   ---
   dimension: 16:9
   theme: vanier
   ---

   # The rest of the presentation

   Muspi merol

The current options for the frontmatter are:

- ``attributes``, for defining the attributes of the elements in the current
  file. Accepts a string with the syntax for attributes. Default value is an
  empty attribute.

- ``toplevel-attributes``, for defining attributes for the whole presentation
  (useful in multi-file setting). Accepts a string with the same syntax as is used for
  attributes. Useful to control the first action executed. Default is ``slip
  enter="~duration:0"``.

- ``theme``, for selecting a theme. Accepts a string: either ``"default"``,
  ``"vanier"`` or a path to a CSS file defining a theme.

- ``css`` for adding css files to the presentation. Accepts a space-separated list of paths. Spaces within paths are not yet possible.

- ``js`` for adding ``.js`` files to the presentation. Accepts a space-separated list of paths. Spaces within paths are not yet possible.

- ``dimension`` for defining the size or aspect ratio of the presentation. Accepts a pixel dimensions in ``"WIDTHxHEIGHT"`` format, like ``1440x1080``. Some dimensions can alternatively be given as a ratio: ``"4:3"`` for ``1440x1080``, and ``"16:9"`` for ``1920x1080``. The default dimension is ``1440x1080``.

- ``highlightjs-theme``, for selecting a highlightjs theme. Accepts the name of
  a theme, corresponding to the name of a file in `this list
  <https://github.com/highlightjs/highlight.js/tree/5697ae5187746c24732e62cd625f3f83004a44ce/src/styles>`_,
  without its extension.

- ``external-ids``, for telling the Slipshow compiler which ``ids`` will be
  present even if they do not seem to be present in the document. Accepts a list
  of space-separated ids. This is just in order to silence some warnings. This
  is useful when including svgs or math where some IDs are given.

Multifile presentations
=======================

When you split your presentation in multiple files, you can define a frontmatter
in each included file. The fields present in multiple files will be combined when
applicable. When the attributes are not applicable, a warning will be shown.
