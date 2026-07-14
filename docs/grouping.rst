========
Grouping
========

The :ref:`attributes section <attributes-ref:attributes>` explained how to give attributes to a single block. However, it did not explain how to give attributes to multiple blocks at the same time.

This is because you can't do that! What you can do though is create a new block that consists of a "group" of blocks, and give that attributes instead. There are two main mechanisms for doing this.

The first way uses indentation to indicate grouping. The second uses a separator rather than a delimiter with a beginning and an end.

.. _using-gt-to-group:

Using ``>``
-----------

You can use ``>`` to group blocks together, just like how Commonmark groups `quotations <https://spec.commonmark.org/0.31.2/#block-quotes>`_. Here is an example:

.. code-block:: markdown

   > Two paragraphs
   >
   > Grouped in a block

Using ``---``
-------------

Like other Markdown-to-slides generators, Slipshow allows you to use "horizontal lines" (such as ``---``) to group blocks together:

.. code-block:: markdown

   Two paragraphs

   Grouped in a block

   ---

   Another group

   ---

   Yet another group

The example above defines three groups, one after the other. It is important that each horizontal line has the same number of ``-`` (and at least three). The separators with the most numbers of dashes have priority:

.. code-block:: markdown

   A

   ---

   B

   ----

   C

will group the ``A``, ``B``, and ``C`` blocks as (``A``, ``B``) in one group, and ``C`` in the other.

You can attach metadata to a group by attaching metadata to the dashes (see the next section):

.. code-block:: markdown

   A

   {#id}
   ---

   B

This attaches metadata to B. Note that a dash separator before the first block is optional, but it's possible to add metadata there too.

Combining both approaches
-------------------------

It is possible to mix-and-match both approaches.

The problem with ``>`` is that the indentation level can quickly become hard to control, making the result difficult to read, and annoying to edit. The problem with ``---`` is that you cannot easily see where it ends.

Sometimes, mixing the approaches helps to clarify the structure of deeply nested blocks. If it does not, consider :doc:`splitting in files <managing-large-presentations>`.

Let's see an example. Which one do you find more readable?

.. code-block::

   Here are some colors:

   {.columns}
   ----
   # Red

   Red is the color of the sun when it sets
   ---
   # Green

   Green is the color of the grass when it's had a lot of water.
   ---
   # Blue

   Blue is the color of the sky when it's sunny
   ----

   They are all beautiful!

.. code-block::

   Here are some colors:

   {.columns}
   > # Red
   >
   > Red is the color of the sun when it sets
   > ---
   > # Green
   >
   > Green is the color of the grass when it's had a lot of water.
   > ---
   > # Blue
   >
   > Blue is the color of the sky when it's sunny

   They are all beautiful!

.. code-block::

   Here are some colors:

   {.columns}
   > > # Red
   > >
   > > Red is the color of the sun when it sets
   >
   > > # Green
   > >
   > > Green is the color of the grass when it's had a lot of water.
   >
   > > # Blue
   > >
   > > Blue is the color of the sky when it's sunny

   They are all beautiful!

   .. code-block::

   Here are some colors:

   {.columns}
   ----
   > # Red
   >
   > Red is the color of the sun when it sets

   > # Green
   >
   > Green is the color of the grass when it's had a lot of water.

   > # Blue
   >
   > Blue is the color of the sky when it's sunny
   ----

   They are all beautiful!
