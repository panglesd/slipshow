=======================
Split in multiple files
=======================

Split the markdown source in multiple files
===========================================

Have a main file, and include additional files with ``{include src=path/to/file.md}``.

For instance, here is a ``main.md`` including the files ``part1.md`` and ``part2.md``:

.. code-block::

   ---
   dimension: 16:9
   ---

   Only the main file should contain the frontmatter.

   {include src=part1.md}

   {include src=part2.md}

Note that you can add additional attributes, for instance if you want
``part1.md`` to be a slip, you can add the ``slip`` attribute:

.. code-block::

   {include src=part1.md slip}

Use external CSS files
======================

If you want to include an external CSS files, use the ``css`` field of the frontmatter:

.. code-block:: markdown

   ---
   css: path/to/file.css
   ---

