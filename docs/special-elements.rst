================
Special elements
================

In addition to the elements described in TODO: link and have a special markup,
attributes can be used to define more elements, such as boxes, subslips,
carousel, ...

This page provides a reference for all such elements.

.. contents:: Outline of the tutorial
   :local:

Boxes, admonitions and math environments
----------------------------------------

The following boxes are available:

- ``block`` to display a regular presentation block,
- ``theorem`` to display a theorem,
- ``definition`` to display a definition,
- ``example`` to display an example,
- ``lemma`` to display a lemma,
- ``corollary`` to display a corollary,
- ``remark`` to display a remark.
- ``proof`` to display a proof.


To create an element listed above, add its name as a class to the block element. Any box may additionally have a ``title=...`` attribute. This attribute cannot yet contain any markup.

.. slipshow-example::

   {.block}
   I'm a block. I could have a title too, if I wanted to.

   {.definition}
   This is a definition

   {.theorem title="Fundamental theorem of definition"}
   The definition is interesting

   {.proof}
   > Suppose it's not interesting.
   >
   > Then it would not have a proof.

Slips and slides
----------------

A slip element is an element with a fixed width (equal to the presentation width) but no fixed height. By default, the whole presentation is in a slip.

So a slip has a number of pixel defining its width (1440 by default, as presentations are 1440x1080 pixels). If the available width for the slip element is different, it will be rescaled to fit it: the pixels change in size, but you still have the same number.

You can ``enter`` a slip with the eponymous action. This zooms on the top part of it.

Slide are just like slips, but they also have a fixed height.

To create a slip or a slide, just give the element the ``slip`` or ``slide`` attribute. This will automatically add a ``enter`` action, unless there is already one or the ``no-enter`` is used.

.. slipshow-example::

   Let's have three parts in this presentation:

   {style=display:flex}
   > {slip}
   > ---
   > # Part 1
   >
   > This is the part 1
   >
   > {slip no-enter}
   > ---
   > # Part 2
   >
   > This is the part 2. It is skipped due to `no-enter`
   >
   > {slip}
   > ---
   > # Part 3
   >
   > This is the part 3.

   {step}


Carousels
---------

Carousels are elements that only display one child at a time. They allow to conveniently change the displayed content of an element, for instance the pages of a PDF. In particular, they are very adapted when you have multiple images, each adding some content to the previous one.

A carousel is created simply by giving it a ``carousel`` attribute. Carousels are then controlled with the ``change-page`` action.

.. slipshow-example::

   Here is a first carousel:

   {carousel change-page=~n:all}
   ----
   A
   ---
   B
   ---
   C
   ----

Includes
--------

Includes are a way to include external markdown files, just as if they were inlined in the file. An include must be a standalone attribute (TODO: link). It must have the ``include`` boolean attribute and ``src="path/to/file.md"`` key-value attribute. It is possible to add other attributes as well.

.. code-block::

   This presentation has two part:

   {include slip src="part1.md"}

   {include slip src="part2.md"}
