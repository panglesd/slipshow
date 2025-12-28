===============================
 Slipshow's syntax for content
===============================

Slipshow's presentation are written in a "What You See Is What You Mean", compared to presentation tools such as PowerPoint, which are "What You See Is What You Get".

In more usual words, PowerPoint lets you visually place blocks, what you edit and what you'll present are the same.

Slipshow, on the contrary, lets you describe your intent (this is a title, this is a definition, this is a block, ...) and does the formatting for you.

In this page, we describe the syntax used to describe this intent. You'll write your presentation as a simple text document, with no formatting but using this specific syntax. From that syntax, Slipshow will be able to format the document.

This syntax is very close to Markdown's syntax. If you are familiar with it, the must-read are the section on metadata annotations, and the section on the differences with Markdown.

Blocks and inlines
==================

In what follows, we will make a difference between what we call blocks, and inlines.

Inlines are the elements that are inside the flow of the text. For instance, bold text, links, italic, mathematic formulas.

Blocks, on the contrary, cannot be put TODO paragraphs, titles, bullet lists, and so on. They take space

Blocks
------

Titles
~~~~~~

Paragraphs
~~~~~~~~~~

A paragraph is made just by writing text. They should be separated by a blank line.

.. code-block:: markdown

   This is a paragraph.

   This is a second paragraph.
   This is part of the second paragraph.

A single newline would not create a new paragraph, but would continue in the paragraph without line break.


Lists
~~~~~

Lists can be started with a dash. Indentation allows to put other blocks in the list.

.. code-block:: markdown

   - This is a list
   - This is another item in the list
   - This is another item, that contains multiple paragraphs.

     This is the second paragraph of the third item
   - This item contains a nested list
     - This is the nested list

Simple lists, that contain only text and without blank lines, are tight lists. They are rendered without margin.

Lists containing other blocks or with blank lines are TODO lists

.. code-block:: markdown

   - This is a tight list
   - With multiple items.

   Let's now see a TODO list:

   - It's not tight because the items are separated by a blank line

   - I'm the second item of the TODO list

Code block
~~~~~~~~~~

Tables
~~~~~~

Math blocks
~~~~~~~~~~~

Inline
------

Links
~~~~~

Bold
~~~~

Italic
~~~~~~

Images
~~~~~~

Inline code
~~~~~~~~~~~

Links
~~~~~

Inline math
~~~~~~~~~~~

Differences with Markdown
=========================


-----------



Extensions to Markdown
=====================

