========
Grouping
========

The :ref:`attributes section <attributes-ref:attributes>` explained how to give attributes to a single block. However, it did not explain how to give attributes to multiple blocks at the same time.

This is because you cannot, what you can do is create a new block, that consists of a "group" of block. There are two main mechanisms for that.

The first one is "indentation-based". The second one is pretty new, as far as I know, as it is a separator rather than a delimitor with a beginning and an end.

.. _using-less-to-group:

Using ``>``
-----------

You can use ``>`` to group blocks together, just like it is used in Commonmark to group them in `quotations <https://spec.commonmark.org/0.31.2/#block-quotes>`_. Here is an example:

.. code-block:: markdown

   > Two paragraphs
   >
   > Grouped in a block


Using ``---``
-------------

Like other markdown-to-slides generator, slipshow allows to use "horizontal lines" (such as ``---``) to group blocks together:

.. code-block:: markdown

   Two paragraphs

   Grouped in a block

   ---

   Another group

   ---

   Yet another group

The example above defines three groups, one after the other. It is important that each horizontal lines have the same number of ``-`` (and at least three). The separators with the most numbers of dashes have priority:

.. code-block:: markdown

   A

   ---

   B

   ----

   C

will group the blocks above as (``A``, ``B``) in one group, and ``C`` in the other.

You can attach metadata to a group by attaching metadata to the dashes (see the next section):

.. code-block:: markdown

   A

   {#id}
   ---

   B

This attaches metadata to B. Note that the a dash separation before the first block is optional, but possible to add metadata.

Combining both approaches
-------------------------

It is possible to mix-and-match both approaches.

The problem with ``>`` is that the identation level can quickly become out of control, making the result not very readable, and a pain to edit. The problem with ``---`` is that you cannot easily see where it ends.

Sometimes, mixing the approach helps improve the experience of deeply nested blocks. If it does not, consider :doc:`splitting in files <split-in-multiple-files>`.

Let's see an example. Which one is more readable for you?

.. code-block::

   Here is are some colors:

   {.columns}
   ----
   # Red

   Red is the color of the sun when it sets
   ---
   # Green

   Green is the color of the grass when it had a lot of water.
   ---
   # Blue

   Blue is the color of the sky when it's blue
   ----

   They are all beautiful!

.. code-block::

   Here is are some colors:

   {.columns}
   > # Red
   >
   > Red is the color of the sun when it sets
   > ---
   > # Green
   >
   > Green is the color of the grass when it had a lot of water.
   > ---
   > # Blue
   >
   > Blue is the color of the sky when it's blue

   They are all beautiful!

.. code-block::

   Here is are some colors:

   {.columns}
   > > # Red
   > >
   > > Red is the color of the sun when it sets
   >
   > > # Green
   > >
   > > Green is the color of the grass when it had a lot of water.
   >
   > > # Blue
   > >
   > > Blue is the color of the sky when it's blue

   They are all beautiful!

   .. code-block::

   Here is are some colors:

   {.columns}
   ----
   > # Red
   >
   > Red is the color of the sun when it sets

   > # Green
   >
   > Green is the color of the grass when it had a lot of water.

   > # Blue
   >
   > Blue is the color of the sky when it's blue
   ----

   They are all beautiful!

