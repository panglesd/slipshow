======
Markup
======

Slipshow's presentation are written in a "What You See Is What You Mean", compared to presentation tools such as PowerPoint, which are "What You See Is What You Get".

In more usual words, PowerPoint lets you visually place blocks, what you edit and what you'll present are the same.
Slipshow, on the contrary, lets you describe your intent ("this text is a title", "this paragraph is a definition block", ...) and does the formatting for you.

In this page, we describe the syntax used to describe this intent. You'll write your presentation as a simple text document, with no formatting but using this specific syntax. From that syntax, Slipshow will be able to format the document.

This syntax is very close to Markdown's syntax. If you are familiar with it, the must-read are the section on metadata annotations, and the section on the differences with Markdown.

Blocks and inlines
==================

In what follows, we will make a difference between what we call blocks, and inlines.

Inlines are the elements that are inside the flow of the text. For instance, bold text, links, italic, mathematic formulas.

Blocks, on the contrary, make the structure of the text. For instance paragraphs, titles, bullet lists, are blocks, as well as columns in a multi-column layout.

This distinction will be important when styling with attributes (TODO).

Blocks
------

Paragraphs
~~~~~~~~~~

A paragraph is made just by writing text. They should be separated by a blank line.

.. slipshow-example::

   This is a paragraph. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.  Donec hendrerit tempor tellus.  Donec pretium posuere tellus.  Proin quam nisl, tincidunt et, mattis eget, convallis nec, purus.  Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.  Nulla posuere.  Donec vitae dolor.  Nullam tristique diam non turpis.  Cras placerat accumsan nulla.  Nullam rutrum.  Nam vestibulum accumsan nisl.

   This is a second paragraph.
   This is part of the second paragraph.

A single newline would not create a new paragraph, but would continue in the paragraph without line break.

Titles
~~~~~~

Titles are made by prefixing the text with ``#``. The more you add ``#``, the smaller the title.

.. slipshow-example::

   # Title 1

   ## Subtitle 1

   ## Subtitle 2

   ##### Subsubsubsubtitle

Lists
~~~~~

Lists can be started with a dash. Indentation allows to put other blocks in the list.

.. slipshow-example::

   - This is a list
   - This is another item in the list
   - This is another item, that contains multiple paragraphs.

     This is the second paragraph of the third item
   - This item contains a nested list
     - This is the nested list

.. note::

   Slipshow's syntax inherits from Markdown's notion of `"tight/loose" lists <https://spec.commonmark.org/0.31.2/#tight>`_.

   In effect, if you find that the items in your list are rendered too close to each others, add a blank line in between each items. The list will become "loose" and the items will be spaced.


Code block
~~~~~~~~~~

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

Tables
~~~~~~

Tables follow the `GFM syntax <https://github.github.com/gfm/#tables-extension->`_:

.. slipshow-example::

   | foo | bar |
   | --- | --- |
   | baz | bim |

They are currently not stylized by default and thus require a bit more effort to use.

Math blocks
~~~~~~~~~~~

You can insert a mathematical block either by enclosing with ``$$`` or with a codeblock with the math language:

.. slipshow-example::

   It's better to get that $$ \left( \sum_{k=1}^n a_k b_k \right)^2 $$
   on its own line. A math block may also be more convenient:

   ```math
   \left( \sum_{k=1}^n a_k b_k \right)^2 < \Phi
   ```

Inline
------

Links and images
~~~~~~~~~~~~~~~~

Links are using the traditional Markdown syntax: ``[text](link target)``.

Images are also included using the traditional Markdown syntax: ``![alternative text](link to image)``.

.. slipshow-example::

   The [slipshow documentation](slipshow.readthedocs.io) should be consulted in case of doubt.

   Here is it's logo:

   ![](https://raw.githubusercontent.com/panglesd/slipshow/refs/heads/main/logo/logo-slipshow.svg)


Bold, italic and inline code
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Bold is made by enclosing with ``**`` characters, italic with ``*`` and inline code with `````.

.. slipshow-example::

   This is **bold**, *italic*, ***bold and italic***, and `inline code`.

Inline math
~~~~~~~~~~~


Inline math is made by enclosing with ``$``.

.. slipshow-example::

   This is the Euler's identity: $e^{i\pi} = - 1$.


Incompatibilities with Markdown
===============================

Quotes
------

The main part of Markdown's syntax that does not translate directly is quoting.
In Markdown, quotes are made with ``>`` at the beginning of the line.
In Slipshow, the ``>`` character is used for grouping (see TODO the relevant section). Grouping is used much more often than quotes in a presentation.

To make a quote in slipshow, combine the grouping and a specific attribute to make it a quote:

.. slipshow-example::

   > This is not a quote

   {blockquote}
   > Cogito Ergo Sum

Thematic breaks
---------------

Thematic breaks are represented as horizontal lines, both in Markdown and Slipshow.

They differ in Markdown and Slipshow, as ``---`` is used by Slipshow for grouping. Instead, use either ``___``, ``***`` or directly the HTML: ``<hr>``.

Beware that horizontal lines may not render in the rendered example (due to being too small). You can add ``hr { border-width: 2px}`` in the editor if that happens.

.. slipshow-example::

   Some thing.

   ___

   Some other thing

   ***

   Another unrelated subject

   <hr>

   Something else.


Titles
------

In Markdown TODO 


Extensions to Markdown
======================

Including videos, pdf, drawings
Attaching metadata
Metadata syntax
Action syntax
Frontmatter
Including videos
