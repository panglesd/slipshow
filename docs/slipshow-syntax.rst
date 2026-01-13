======
Markup
======

Slipshow's presentation are written in a "What You See Is What You Mean", compared to presentation tools such as PowerPoint, which are "What You See Is What You Get".

In more usual words, PowerPoint lets you visually place blocks, what you edit and what you'll present are the same.
Slipshow, on the contrary, lets you describe your intent ("this text is a title", "this paragraph is a definition block", ...) and does the formatting for you.

In this page, we describe the syntax used to describe this intent. You'll write your presentation as a simple text document, with no formatting but using this specific syntax. From that syntax, Slipshow will be able to format the document.

.. note::

   This syntax is very close to Markdown's syntax, however subtly different. If you are familiar with Markdown, see :ref:`where it differs <markdown>`

.. contents:: Outline
   :local:

Paragraphs
----------

A paragraph is made just by writing text. They should be separated by a blank line.

.. slipshow-example::

   This is a paragraph. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.  Donec hendrerit tempor tellus.  Donec pretium posuere tellus.  Proin quam nisl, tincidunt et, mattis eget, convallis nec, purus.  Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.  Nulla posuere.  Donec vitae dolor.  Nullam tristique diam non turpis.  Cras placerat accumsan nulla.  Nullam rutrum.  Nam vestibulum accumsan nisl.

   This is a second paragraph.
   This is part of the second paragraph.

A single newline would not create a new paragraph, but would continue in the paragraph without line break.

Headings
--------

Titles are made by prefixing the text with ``#``. The more you add ``#``, the smaller the title.

.. slipshow-example::

   # Title 1

   ## Subtitle 1

   ## Subtitle 2

   ##### Subsubsubsubtitle

Bold and italic
---------------

Bold is made by enclosing with ``**`` characters and italic by enclosing with ``*``.

.. slipshow-example::

   This is **bold**, *italic*, and ***bold and italic at the same time***.

Links
-----

Links are included with the following syntax: ``[text](link target)``.


Images, videos, audios, PDFs, drawings
--------------------------------------

Images and the like are included with the following syntax: ``![alternative text](link to file)``.

SVGs must have the ``svg`` attribute (TODO: do) or extension to be included as an svg and not as an image (to be able to add classes and actions to it).

Videos must either have the ``video`` attribute (TODO: do) or the file must have one of the following extension:   ``.3gp``, ``.mpg``, ``.mpeg``, ``.mp4``, ``.m4v``, ``.m4p``, ``.ogv``, ``.ogg``,  ``.mov``, ``.webm``.

Audios must either have the ``audio`` attribute (TODO: do) or the file must have one of the following extension:   ``.aac``, ``.flac``, ``.mp3``, ``.oga``, ``.wav``.

Pdfs must either have the ``pdf`` attribute (TODO: do) or the file must have the ``.pdf`` extension.

Drawings must have the file have the ``.draw`` extension.

.. slipshow-example::

   The [slipshow documentation](slipshow.readthedocs.io) should be consulted in case of doubt.

   Here is it's logo:

   ![](https://raw.githubusercontent.com/panglesd/slipshow/refs/heads/main/logo/logo-slipshow.svg)

Lists
-----

Lists can be started with a dash. Indentation allows to put other blocks in the list. Lists can be numbered too.

.. slipshow-example::

   - This is a list
   - This is another item in the list
   - This is another item, that contains multiple paragraphs.

     This is the second paragraph of the third item
   - This item contains a nested list
     - This is the nested list
     - It has two items

   1. This is another,
   2. numbered,
   3. list.

.. note::

   Slipshow's syntax inherits from Markdown's notion of `"tight/loose" lists <https://spec.commonmark.org/0.31.2/#tight>`_.

   In effect, if you find that the items in your list are rendered too close to each others, add a blank line in between each items. The list will become "loose" and the items will be spaced.

Mathematics
-----------

The syntax for mathematical formulas is the same as the one in Latex. You can include math in any text (inline formulas), or as a block.

You can insert a mathematical block either by enclosing with ``$$`` or with a codeblock with the math language.
To add some inline mathematics, enclose with a single ``$``.

.. slipshow-example::

   This is a mathematic block $$ \left( \sum_{k=1}^n a_k b_k \right)^2  < \Phi$$ which will render in its own line.
   A math block may also be more convenient:

   ```math
   \left( \sum_{k=1}^n a_k b_k \right)^2 < \Phi
   ```

   This is the Euler's identity: $e^{i\pi} = - 1$.

Code
----

Snippets of source code can be included either inline (in the flow of the text) or as a code block.

Inline code are inserted by enclosing with `````.
Code blocks are blocks containing code to display verbatim, and syntax highlighted. They are created with ```````.

.. slipshow-example::

   This is a code-block:

   ```
   Code goes here
   ```

   It'll try to detect the language and syntax highlight it. You can help it by providing a language:

   ```ocaml
   let salut = "hello"
   ```

   If you don't want a highlight, use "text":

   ```text
   Code goes here
   ```

   The expression `factorial(5)` denotes the factorial of `5`.

HTML
----

Including HTML is done just like in Markdown for `inline <https://spec.commonmark.org/0.31.2/#raw-html>`_ and `blocks <https://spec.commonmark.org/0.31.2/#html-blocks>`_. Use the Commonmark spec for reference, but here is a less precise introduction.

You can include HTML directly in the flow, provided the HTML is separated from the text by at least one space.

If a line following a blank link consist of an HTML tag, the following lines will be interpreted as HTML until the next blank line.

Tables
------

Tables follow the `GFM syntax <https://github.github.com/gfm/#tables-extension->`_:

.. slipshow-example::

   | foo | bar |
   | --- | --- |
   | baz | bim |

They are currently not stylized by default and thus require a bit more effort to use.

Thematic breaks
---------------

A thematic break is a change of subject represented graphically, often by a horizontal line, or sometimes in books a triple asterisk.

To add a thematic break, use either ``___``, ``***`` or (directly the HTML: ``<hr>``).

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

Since in Slipshow, the ``>`` character is used for :doc:`grouping <grouping>`, quotes are not made like in Commonmark. Instead, they can be added as :ref:`special elements <blockquote-in-special-elements>`.

.. slipshow-example::

   > This is not a quote

   {blockquote}
   > Cogito Ergo Sum


Setext Headings
===============

Markdown's `Setext headings <https://spec.commonmark.org/0.31.2/#setext-headings>`_ cannot be used in Slipshow. Use :ref:`ATX headings <slipshow-syntax:headings>`.
