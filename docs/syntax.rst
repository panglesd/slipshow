==================
 Syntax reference
==================

The slipshow syntax can be described in several parts.

- One part is the document itself, disregarding any slipshow-specific data. The syntax is (almost) exactly markdown, but there are a few modifications that are described and justified here.
- Since you need to add metadata to describe the flow of your presentation, slipshow includes some special syntax to attach metadata to add to specific parts of your presentation. The "attachment" syntax is very close to what other markdown extension do, but expand and modifies some constructs. This is explained and justified in the next section.
- Finally, there is the syntax for the metadata themself. Slipshow include many keyword to allow you to describe the flow of your presentation in a convenient way.

Defining a document
===================

The slipshow syntax is based on CommonMark, whose syntax is well `specified <https://spec.commonmark.org>`_. The "`60 second to learn Markdown <https://commonmark.org/help/>`_" is a good and quick way to learn the syntax.

Some extensions to CommonMarkd are quite common, and available in the slipshow syntax:
- The table extension, as specified `here <https://github.github.com/gfm/#tables-extension->`_.
- The math extension, as specified `here <https://erratique.ch/software/cmarkit/doc/Cmarkit/index.html#ext_math>`_.
- The strikethrough extension, as specified `here <https://erratique.ch/software/cmarkit/doc/Cmarkit/index.html#ext_strikethrough>`_.


.. warning::
   Quotes do not have the same syntax as commonmark!

In addition to extensions, there is one modification to the Markdown syntax! The markdown syntax for `block quotation <https://spec.commonmark.org/0.31.2/#block-quotes>`_ is not considered to enclose a quotation. It instead simply groups blocks together, without assigning a default meaning to the group. The meaning can be given using the attribute syntax.

For block quotes, use the html syntax until better support is added! (Slipshow is still in beta version.)

Attaching metadata
==================

Metadatas are the backbone of your slipshow presentation! The tricky part is that we don't want it to cripple the readability of the source. Still, it is in my opinion and experience much better to have it mixed inside the document. It makes it much easier to reason locally on what the presentation will look like.

Attaching metadata is done very similarly to both pandoc's markdown and djot.

Metadatas (also called attributes) are enclosed in curly braces: ``{}``. We can attach metadata to two kind of document parts: blocks (such as paragraphs, code blocks, title, definitions, ...) and inlines (such as words or group of words, code spans, links, images, ...).

Block metadata
--------------

To add attributes to a block, put the curly braces on an (otherwise empty) line just above. That is, for a heading:

.. code-block:: markdown

		{the attributes}
		# The title

See the next section for the content on the attributes. If you want to add an attribute to a group of several blocks, indent all of them using ``>``. For instance

.. code-block:: markdown

		{the attributes}
		> Some text
		>
		> ```
		> A code block
		> ```

An attribute cannot have line breaks. However, if two lines of attributes are in a row, they are merged.

An attribute that is followed by an empty line is a _standalone attribute_. They are useful in the context of slipshow, to give an instruction (such as a pause) in the flow of the presentation, without being tied to a specific element!

.. code-block:: markdown

		Some text

		{a standalone attribute}

		Some other text

Inline metadata
---------------

If you want to give attributes to inline elements, the syntax is quite similar: attributes are enclosed in curly braces. What changes is how they are attached to a specific element.

Attributes are attached to the inline element they touch. For instance:

.. code-block:: markdown

		Some text and{A} some {B}other text and {C} finally an end.

		Works with **bold**{D} and other `inline elements`{E}

In this example, ``A`` is attached to ``and``, ``B`` to ``other``,  ``C`` is a standalone attribute, ``D`` is attached to ``**bold**`` and ``E`` to ```inline elements```.

If you want to attach an attribute to a group of inlines, you can use the ``[...]{attributes}`` syntax. For instance:

.. code-block:: markdown

		Works with [groups of **bold** and other `inline elements`]{F}

However, sometimes putting long attributes in the middle of the text can hurt readability. Often, the attributes are the same and are repeated, which makes it even worse. Slipshow eases this by using referenced attributes. Similarly to footnotes and referenced links, they text only contains a reference, and the attribute itself is defined elsewhere:

.. code-block:: markdown

		Some [text][A] [with][A] [many][A] [attributed][A] [words][A].

		[A]: {many long attributes}


Not perfect, but much better than the version where all words are given the attributes separately.

Describing your presentation flow
=================================

Now that we know how to assign attributes to a part of the document, we can continue with the "true" slipshow syntax: the metadata itself.

This metadata is used to tell slipshow how the presentation should go. When to pause, when to move the window, down or up.

Let's start first with the "general" syntax for the content inside the curly braces.

.. code-block:: markdown

		{#fermat .theorem pause up-at-unpause=title1 exec-at-unpause="script1 script2"}
		Some content

Attributes are separated by space.

A word starting with ``#`` gives an id to the associated elements. For instance, above, the ``fermat`` id is given to the content. Ids are used to refer to other elements, for instance ``title1``, ``script1`` and ``script2`` are likely to be reference to other ids in the example above.

A word starting with ``.`` is a class. Classes are used both controlling the layout, especially with themes. For instance, the content above is assigned the ``theorem`` class, which will make it render as a theorem. A complete list of class supported by slipshow is available later in this section, but custom themes might add some more.

A single word is a "flag attribute". In the example above, ``pause`` is a flag attribute. The meaning of all slipshow attributes is given later in this section!

Key-value attributes are defined using an equal sign (``=``). They need a key, and a value. If the value contains spaces or other dubious characters, they should be enclosed in quotes. The quotes are not part of the value of they key attributes! In the example above, the key ``up-at-unpause`` is given value ``title1``, while the key ``exec-at-unpause`` is given the value ``script1 script2``.

Some attribute can be used both as a flag attribute and as a key-value attribute.

List of classes
---------------

The following classes are meant to be added to a block element, and will display the element as a presentation block. They all accept a ``title=...`` attributes.

- ``block`` to display a regular presentation block,
- ``theorem`` to display a theorem,
- ``definition`` to display a definition,
- ``example`` to display an example,
- ``lemma`` to display a lemma,
- ``corollary`` to display a corollary,
- ``remark`` to display a remark.

List of attributes
------------------

Pause attributes
~~~~~~~~~~~~~~~~

``pause``
  The pause attribute tells the slipshow engine that there is going to be a pause at this element. This element and every element after that in the document will be hidden.

  Each time the user advances in the presentation (e.g by pressing the ``Down`` key), the first ``pause`` or ``step`` is consumed, possibly triggering some effects.

``step``
  Same as ``pause``, but no elements is hidden. Only used to activate effects when consumed.

Action attributes
~~~~~~~~~~~~~~~~~

These attributes are actions that will be executed when a ``pause`` or ``step`` attribute attached to the same element is consumed. All of them accepts a value, consisting of the ``id`` of an element to apply the action to.

``down`` or ``down-at-unpause``
  Moves the screen untils the element is at the bottom of the screen.

``up`` or ``up-at-unpause``
  Moves the screen untils the element is at the top of the screen.

``center`` or ``center-at-unpause``
  Moves the screen untils the element is centered.

``focus`` or ``focus-at-unpause``
  Focus on the element by zooming on it.

``unfocus`` or ``unfocus-at-unpause``
  Unfocus by going back to the last position before a focus.

``static-at-unpause``
  Make the element ``static``. By "static" we mean the css styling ``position:static; visibility:visible`` will be applied.

``unstatic-at-unpause``
  Make the element ``unstatic``. By "unstatic" we mean the css styling ``position:absolute; visibility:hidden`` will be applied.

``reveal-at-unpause``
  Reveal the element. By "revealing" we mean the css styling ``opacity:1`` will be applied.

``exec-at-unpause``
  Execute the slipscript.

Custom scripts
--------------

Use a slipscript code block to add a script, and ``exec-at-unpause`` to execute it. The script should return the function to undo the change.

.. code-block:: markdown

		{exec-at-unpause}
		```slip-script
                let elem = document.querySelector("#id")
		let old_value = elem.style.opacity;
                elem.style.opacity = "1";
                return {undo : () => { elem.style.opacity = old_value }}
		```

