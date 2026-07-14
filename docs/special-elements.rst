================
Special elements
================

In addition to :doc:`elements with dedicated markup <slipshow-syntax>`, placing attributes before content blocks
can turn them into elements, such as boxes, subslips, carousels, and more.

This page provides a reference for all such elements.

.. contents::
   :local:

Boxes, admonitions, and math environments
-----------------------------------------

The following box types are available:

- ``block`` to display a regular presentation block,
- ``theorem`` to display a theorem,
- ``definition`` to display a definition,
- ``example`` to display an example,
- ``lemma`` to display a lemma,
- ``corollary`` to display a corollary,
- ``remark`` to display a remark.
- ``proof`` to display a proof.

To create one of these elements, add its name as a class to the block element. Any box may additionally have a ``title=...`` attribute. The attribute's value cannot contain any markup.

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

A slip element has a fixed width (equal to the presentation width) but no fixed height. By default, the whole presentation is in a slip.

A slip's width is defined in pixels, 1440 by default, as presentations are 1440x1080 pixels. If the available width for the slip element is different (for example if it is nested within another slip), it will be scaled to fit: the pixels change in size, but you still have the same number of them.

You can ``enter`` a slip with the eponymous action. This zooms to display the top part of it, i.e. full-width, scrolled to the top.

Slides are just like slips, but they also have a fixed height.

To create a slip or a slide, add a ``slip`` or ``slide`` element. This will automatically add an ``enter`` action, unless one is already assigned, or the ``no-enter`` attribute is used.

.. slipshow-example::

   Let's have three parts in this presentation:

   {style=display:flex}
   > {slip}
   > ---
   > # Part 1
   >
   > This is part 1.
   >
   > {slip no-enter}
   > ---
   > # Part 2
   >
   > This is part 2. It is skipped due to the `no-enter` attribute on it.
   >
   > {slip}
   > ---
   > # Part 3
   >
   > This is part 3.

   {step}

Carousels
---------

Carousels are elements that only display one child element at a time. This provides a convenient way to change the displayed content of an element, for instance to step through the pages of a PDF. They are particularly useful when you have a sequence of images, each adding some content to the previous one.

Create a carousel by adding a ``carousel`` element. It will then be controlled with a ``change-page`` action.

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

The carousel will take the height of its currently displayed element, unless the ``carousel-fixed-size`` class is added to the carousel, in which case it takes the height of the tallest element.

Includes for Markdown and HTML
------------------------------

Includes are a way to include external Markdown/HTML files, just as if they were
inlined in the file, just like the ``![](...)`` syntax that Markdown uses for images, but for blocks of external content.
An include must be a standalone element. It must have the ``include`` boolean
attribute and a ``src`` attribute pointing to the path of the included resource, for example ``src="path/to/file.slp"``. It is possible to
add other attributes as well.

.. code-block::

   This presentation has two parts:

   {include slip src="part1.slp"}

   {include slip src="part2.slp"}

   {include src="conclusion.html"}

   {include src="drawing.svg"}

Recall that for inline elements, it is possible to embed images, SVGs, videos, audio clips, PDFs, HTML files, and drawings directly using the Markdown image syntax:

.. code-block::

   This sentence includes ![](file.html) some raw html from an external file.

.. _blockquote-in-special-elements:

Blockquotes
-----------

Since ``>`` is used for :ref:`using-less-to-group`, we can create them by assigning the ``blockquote`` attribute.

.. code-block::

   {blockquote}
   This is a blockquote.

   {blockquote}
   > This is a blockquote.
   >
   > With multiple paragraphs.

   > This is NOT a blockquote.
   >
   > Even with multiple paragraphs.

HTML spans and blocks
---------------------

While Markdown conveniently allows inline HTML, particularly useful when its limited formatting abilities fall short, the rules for it are not
obvious. If you want to be sure that some content is included as HTML, use code blocks and code spans, with the ``as-html`` attribute.

.. code-block::

   {as-html}
   ```
   <marquee>This is included as html, not as a code block</marquee>
   ```

   This text includes `<blink>some html</blink>`{as-html}.

For consistency, it is also possible to import HTML as a code block by setting the language to ``=html``:

.. code-block::

   ```=html
   <marquee>This is included as html, not as a code block</marquee>
   ```
