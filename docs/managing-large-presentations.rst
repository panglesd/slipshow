============================
Managing large presentations
============================

Splitting presentations across multiple files
=============================================

Big presentations can rapidly become difficult to manage in a single file, so create a "main" file, and include additional files with ``{include src=path/to/file.slp}``.

For instance, here is a ``main.slp`` that includes the files ``part1.slp`` and ``part2.slp``:

.. code-block::

   ---
   dimension: 16:9
   ---

   Only the main file should contain the frontmatter.

   {include src=part1.slp}

   {include src=part2.slp}

Note that you can add additional attributes to the ``include``, for instance if you want
``part1.slp`` to be a slip, you can add the ``slip`` attribute:

.. code-block::

   {include src=part1.slp slip}

Using external CSS files
========================

To include an external CSS file, use the ``css`` field in the :doc:`frontmatter <frontmatter>`:

.. code-block:: markdown

   ---
   css: path/to/file.css
   ---

Combining frontmatter
=====================

When you split your presentation in multiple files, you can define a frontmatter
in each included file. The fields present in multiple files will be combined when
applicable. When the attributes are not applicable, a warning will be shown.
