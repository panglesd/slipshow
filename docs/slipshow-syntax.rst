======
Markup
======

Slipshow's presentations are written using a "What You See Is What You Mean" approach, compared to presentation tools such as PowerPoint, which are "What You See Is What You Get".

In more usual words, PowerPoint lets you lay out your presentation visually; what you edit and what you'll present are the same.
Slipshow takes a different approach: you describe your intent ("this text is a title", "this paragraph is a definition", …) and Slipshow does the formatting for you.

In this page, we describe the syntax used to describe this intent. You'll write your presentation as a plain text document, with no formatting, but using this specific syntax. From that syntax, Slipshow will be able to format the presentation.

.. note::

   Slipshow's syntax is very close to Markdown, but it's subtly different in places. If you are familiar with Markdown, see :ref:`where it differs <markdown>`

.. contents:: Outline
   :local:

Paragraphs
----------

A paragraph is made just by writing text. Paragraphs should be separated by a blank line.

.. slipshow-example::

   This is a paragraph. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.  Donec hendrerit tempor tellus.  Donec pretium posuere tellus.  Proin quam nisl, tincidunt et, mattis eget, convallis nec, purus.  Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.  Nulla posuere.  Donec vitae dolor.  Nullam tristique diam non turpis.  Cras placerat accumsan nulla.  Nullam rutrum.  Nam vestibulum accumsan nisl.

   This is a second paragraph.
   This is part of the second paragraph, not a new third one.

A single newline does not create a new paragraph, but continues the current paragraph *without* a line break.

Headings
--------

Headings are made by prefixing the text with ``#`` and a space. Each ``#`` you add bumps the heading level, usually resulting in a smaller title.

.. slipshow-example::

   # Title 1

   ## Subtitle 1

   ## Subtitle 2

   ### Sub-subtitle

   ##### Subsubsubsubtitle

Bold and italic emphasis
------------------------

Text can be made italic by putting a ``*`` character either side of it, bold by using ``**``, and both at once using ``***``.

.. slipshow-example::

   This is **bold**, *italic*, and ***bold and italic at the same time***.

Links
-----

Create links with this syntax: ``[alternative text](link target)``.

Images, SVGs, video, audio, PDFs, HTML, drawings
------------------------------------------------

Images and several other objects are included with the following syntax:
``![alternative text](path/to/file.extension)``.

The kind of media that is included (image, video, etc) is by default inferred from the extension. For instance, a file ending with ``.png`` is considered an image, while a file ending in ``.mp3`` is considered an audio file.
However, it is possible to override this convention by using an :doc:`attribute <attributes-ref>`. For instance: ``![](file.mp4){audio}`` or ``![](file.svg){image}``.

Here are the possibilities:

+------------+-------------+--------------------------+
| Media type | Attribute   | Extensions               |
+============+=============+==========================+
| Image      | ``image``   | ``.png``, ``.jpg``,      |
|            |             | ``.jpeg``, ``.gif``,     |
|            |             | ``.bmp``, ``.tiff``      |
+------------+-------------+--------------------------+
| SVG        | ``svg``     | ``.svg``                 |
+------------+-------------+--------------------------+
| Video      | ``video``   | ``.3gp``, ``.mpg``,      |
|            |             | ``.mpeg``, ``.mp4``,     |
|            |             | ``.m4v``, ``.m4p``,      |
|            |             | ``.ogv``, ``.ogg``,      |
|            |             | ``.mov``, ``.webm``      |
+------------+-------------+--------------------------+
| Audio      | ``audio``   | ``.aac``, ``.flac``,     |
|            |             | ``.mp3``, ``.oga``,      |
|            |             | ``.wav``                 |
+------------+-------------+--------------------------+
| PDF        | ``pdf``     | ``.pdf``                 |
+------------+-------------+--------------------------+
| HTML       | ``html``    | ``.html``                |
+------------+-------------+--------------------------+
| Drawing    | ``draw``    | ``.draw``                |
+------------+-------------+--------------------------+

.. slipshow-example::

   Here is the Slipshow logo:

   ![Slipshow logo](https://cdn.jsdelivr.net/gh/panglesd/slipshow@main/logo/logo-slipshow.svg)

Lists
-----

Lists can be started with a dash. Indentation allows you to put other blocks within list items. Lists can be numbered too.

.. slipshow-example::

   - This is a list item
   - This is another item in the list
   - This is another list item that contains multiple paragraphs.

     This is the second paragraph of the third item
   - This item contains a nested list
     - This is the nested list
     - It has two items

   1. This is a
   2. numbered
   3. list.

.. note::

   Slipshow's syntax inherits from Markdown's notion of `"tight/loose" lists <https://spec.commonmark.org/0.31.2/#tight>`_.

   In effect, if you find that the items in your list are rendered too close to each other, add a blank line between each item. The list will become "loose" and the items will be spaced.

Mathematics
-----------

Mathematical formulae can be inserted using `LaTeX syntax <https://www.latex-project.org/help/documentation/amsldoc.pdf>`_. You can include mathematical markup inline, or as a block.

Create a mathematical block either by enclosing it in ``$$`` or using a code block with the ``math`` language.
To add some inline mathematics, enclose with a single ``$``.

.. slipshow-example::

   This is a block math element $$\left( \sum_{k=1}^n a_k b_k \right)^2  < \Phi$$ which will render in its own line.

   A math block may be more convenient:

   ```math
   \left( \sum_{k=1}^n a_k b_k \right)^2 < \Phi
   ```

   This is Euler's identity: $e^{i\pi} = - 1$.

Code
----

Snippets of source code can be included either inline (in the flow of the text) using single backticks: ````` or as a block using three backticks at their start and end: ```````. Code will usually be formatted using a monospaced font.

Code blocks are blocks containing code to display verbatim, and syntax highlighted.

.. slipshow-example::

   This is a code-block:

   ```
   Code goes here
   ```

   It'll try to detect the language and apply syntax highlighting, but you can help it by specifying the language immediately after the opening backticks:

   ```ocaml
   let salut = "hello"
   ```

   If you don't want highlighting, use "text":

   ```text
   Code goes here
   ```

   The expression `factorial(5)` denotes the factorial of `5`.

HTML
----

Including HTML is done in the same way as Markdown for `inline <https://spec.commonmark.org/0.31.2/#raw-html>`_ and `blocks <https://spec.commonmark.org/0.31.2/#html-blocks>`_. Use the Commonmark spec for reference, but here is a less-precise introduction.

You can include HTML directly in the flow, provided the HTML is separated from the text by at least one space.

If a line following a blank line starts with an HTML tag, the following lines will be interpreted as HTML until the next blank line.

Tables
------

Tables follow the `GFM syntax <https://github.github.com/gfm/#tables-extension->`_:

.. slipshow-example::

   | foo | bar |
   | --- | --- |
   | baz | bim |

They are currently not styled by default and thus require a bit more effort to use.

Thematic breaks
---------------

A thematic break is a change of subject represented graphically, often by a horizontal line, or sometimes a triple asterisk.

To add a thematic break, use either ``___``, ``***``, or an HTML ``<hr>`` tag.

Beware that horizontal lines may not render in the rendered example (due to being too small). You can add ``hr { border-width: 2px}`` in the editor if that happens.

.. slipshow-example::

   Some thing.

   ___

   Some other thing

   ***

   Another unrelated subject

   <hr>

   Something else.

.. _markdown:

Incompatibilities with Markdown
-------------------------------

Quotes
======

Since in Slipshow, the ``>`` character is used for :doc:`grouping <grouping>`, block quotes do not use CommonMark's standard approach. Instead, they can be added as :ref:`special elements <blockquote-in-special-elements>`.

.. slipshow-example::

   > This is not a quote

   {blockquote}
   > Cogito Ergo Sum

Setext Headings
===============

Markdown's `Setext headings <https://spec.commonmark.org/0.31.2/#setext-headings>`_ cannot be used in Slipshow. Use :ref:`ATX headings <slipshow-syntax:headings>`.
