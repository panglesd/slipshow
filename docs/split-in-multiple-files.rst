=======================
Split in multiple files
=======================

Split the source in multiple files
==================================

Have a main file, and include additional files with ``{include src=path/to/file.slp}``.

For instance, here is a ``main.slp`` including the files ``part1.slp`` and ``part2.slp``:

.. code-block::

   ---
   dimension: 16:9
   ---

   Only the main file should contain the frontmatter.

   {include src=part1.slp}

   {include src=part2.slp}

Note that you can add additional attributes, for instance if you want
``part1.slp`` to be a slip, you can add the ``slip`` attribute:

.. code-block::

   {include src=part1.slp slip}

Use external CSS files
======================

If you want to include an external CSS files, use the ``css`` field of the frontmatter:

.. code-block:: markdown

   ---
   css: path/to/file.css
   ---

