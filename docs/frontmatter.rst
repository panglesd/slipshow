===========
Frontmatter
===========

The frontmatter allows to define metadata for the whole presentation. For every CLI option, there is a corresponding frontmatter option.

It must start the input file with a ``---``, and the frontmatter ends with the
next ``---``. Inside, the metadata is given using a key-value syntax, with ``:``
used for the separation. Not quotes are needed, but no newline are accepted in
the values. I'll switch to yaml at some point...

.. code-block:: markdown

   ---
   dimension: 16:9
   theme: vanier
   ---

   # The rest of the presentation

   Muspi merol

The current options for the frontmatter are:

- ``toplevel-attributes``, for defining the attributes of the topmost
  container. Accepts a string with the syntax for attributes.

- ``theme``, for selecting a theme. Accepts a string: either ``"default"``,
  ``"vanier"`` or a path to a file.

- ``css`` for adding css files to the presentation. Accepts a space-separated list of paths. Spaces in path are not possible yet.

- ``dimension`` for defining the dimension of the presentation. Accepts a
  string, either ``"4:3"`` (``1440x1080``, the default), ``"16:9"``
  (``1920x1080``), or ``"WIDTHxHEIGHT"``.
