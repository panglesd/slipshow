==========
Attributes
==========

The Attribute Syntax
====================

Attributes are metadata that you can add to an existing element. They will always be enclosed in the ``{`` and ``}`` characters, and are very heavily inspired by `pandoc's attributes <https://pandoc.org/MANUAL.html#extension-attributes>`_.

Here is a typical set of attributes:

.. code-block:: markdown

   {#example .definition title="Hello there" focus}

It consists of a list of space-separated attributes.

Attributes can be one of the following:

- **An identifier**. This is represented with a ``#`` followed by the name of the id. For instance: ``#example`` represents the identifier ``example``.

- **A class**. This is represented with a ``.`` followed by the name of the class. For instance: ``.definition`` represents the class ``definition``.

- **A key-value attribute**. This is represented by ``key=value``. For instance ``title=Hello`` is such an attribute. Simple and double quotes can be used to have spaces in the value.

- **A flag attribute**. It is an attribute that does not have a value, only a name. For instance, ``focus`` is such an attribute.

A single identifier must be given to an element, and it must be unique amongst other elements. Multiple classes can be given to an element, and classes can be shared between elements.

Key-value and flag attributes can be any of those defined in :doc:`actions-api` or :doc:`special-elements`, or any valid HTML attribute.

Attaching metadata
==================

Standalone attributes
---------------------

A set of attributes that is separated from the rest of the content by blank lines is *standalone*. The attributes are attached to en "empty" element. It is useful in the context of slipshow, to give an instruction (such as a pause) in the flow of the presentation, without being tied to a specific element!

.. code-block:: markdown

   Some text

   {pause}

   Some other text


Blocks and inlines
------------------

An important distinction needs to be made between inline, and block, elements.

Inlines are the elements that are inside the flow of the text. For instance, bold text, links, italic, mathematic formulas.

Blocks, on the contrary, make the structure of the text. For instance paragraphs, titles, bullet lists, are blocks, as well as columns in a multi-column layout. Most of the time, they take the full horizontal space.

This distinction is relevant here, as the way to add attributes will be specific for each of the two cases. And sometimes, it will be important to distinguish the two cases:

Here is an example where you set the background of an element to red, through an attribute. In the first case, you attach it to the paragraph. In the second case, you attach it to the text of the paragraph.

.. slipshow-example::

   {style="background:red"}
   The attribute is attached to the paragraph.


   [The attribute is attached to the text.]{style="background:red"}

This confusion happens often with :ref:`metadata for images <image-metadata>`.

.. _block-metadata:

Block metadata
--------------

To attach attributes to a block, put the curly braces on an (otherwise empty) line just above. That is, for a heading:

.. code-block:: markdown

   {the attributes}
   # The title

If you want to attach an attribute to a group of several blocks, use :doc:`grouping <grouping>`. For instance, indent all of them using ``>``:

.. code-block:: markdown

   {the attributes}
   > Some text
   >
   > ```
   > A code block
   > ```

An attribute cannot have line breaks. However, if two lines of attributes are in a row, they are merged.

Inline metadata
---------------

If you want to give attributes to inline elements, the syntax is quite similar: attributes are enclosed in curly braces. What changes is how they are attached to a specific element.

Attributes are attached to the inline element they touch. For instance:

.. code-block:: markdown

   Some text and{A} some {B}other text and {C} finally an end.

   Works with **bold**{D} and other `inline elements`{E}

In this example, ``A`` is attached to ``and``, ``B`` to ``other``,  ``C`` is a standalone inline attribute, ``D`` is attached to ``**bold**`` and ``E`` to ```inline elements```.

If you want to attach an attribute to a group of inlines, you can use the ``[...]{attributes}`` syntax. For instance:

.. code-block:: markdown

   Works with [groups of **bold** and other `inline elements`]{F}

However, sometimes putting long attributes in the middle of the text can hurt readability. Often, the attributes are the same and are repeated, which makes it even worse. Slipshow eases this by using referenced attributes. Similarly to footnotes and referenced links, they text only contains a reference, and the attribute itself is defined elsewhere:

.. code-block:: markdown

		Some [text][A] [with][A] [many][A] [attributed][A] [words][A].

		[A]: {many long attributes}


Not perfect, but much better than the version where all words are given the attributes separately.


.. _image-metadata:


Metadata for images
-------------------

Attaching metadata for images is a good example of where the distinction between blocks and inline is relevant, but also confusing.

Consider the following small piece of markup:

.. code-block::

   Have a look at the following image:

   ![](image.png)

Images are inline elements (they can be included in the middle of text), but this one is the only element of a block (a paragraph here). So, there are two ways to attach attributes to it: as an inline element, or as a block element.

We illustrate these two possibilities by adding borders to the element on which the attributes are applied:

.. slipshow-example::

   <style> .with-border { border: 10px solid red;} img { vertical-align: bottom } </style>

   In the following image, the attribute is attached to its containing block:

   {.with-border}
   ![](https://picsum.photos/id/29/500/225)

   In the following image, the attribute is attached to the image:

   ![](https://picsum.photos/id/29/500/225){.with-border}

Both versions can be useful. For instance, centering the image is a property of the containing block, while the width of the image is a property of itself. So pay attention when assigning attributes to images!

.. slipshow-example::

   The following image is centered and occupy half the available width:

   {style="text-align:center"}
   ![](https://picsum.photos/id/29/500/500){width=50%}

