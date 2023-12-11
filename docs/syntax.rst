Syntax reference
================

The slipshow syntax can be described in several parts.

- One part is the document itself, disregarding any slipshow-specific data. The syntax is (almost) exactly markdown, but there are a few modifications that are described and justified here.
- Since you need to add metadata to describe the flow of your presentation, slipshow includes some special syntax to attach metadata to add to specific parts of your presentation. The "attachment" syntax is very close to what other markdown extension do, but expand and modifies some constructs. This is explained and justified in the next section.
- Finally, there is the syntax for the metadata themself. Slipshow include many keyword to allow you to describe the flow of your presentation in a convenient way.

Defining a document
--------------------

Basically, this is commonmark syntax, with some additions, and one notable modifications. For slef-containedness, here is a short description of the syntax, refer to the standard for more.

- Paragraphs are just a block of text. Two paragraphs should be separated by an empty line.
- Headings are defined with a line starting by ``#``. The number of ``#`` defines the level of the heading, so ``### Hello`` is a subsubheading.
- Code blocks are ...
- Links are
- Html syntax 

.. warning::
   Quotes do not have the same syntax as commonmark! For this reason, they are explained later.

In addition to this you have some additions to markdown

- Math is
- Tables are
- ...

Since they are common in many presentations, slipshow additionally provide some syntax for blocks such as theorems, definitions, proofs, alerts, and regular blocks, in the following way:

.. code-block:: markdown

		{.theorem title="My (optional) theorem title"}
		This is a theorem

		{.definition}
		> This is a definition containing...
		>
		> multiple paragraphs!

So, in order to make such blocks, just give them the approriate class amongst: ``definition``, ``block``, ``proof``, ``theorem``, ``note``.

And if the definition lasts for multiple blocks, indent all those blocks using ``>``. Note that this is why the syntax for quotes differ in slipshow: it is more common to group blocks to give them a single attribute, than to add proper quotes!

In order to add quotes, just use html syntax (better support will be added).

Attaching metadata
------------------

Metadatas are the backbone of your slipshow presentation! The tricky part is that we don't want it to cripple the readability of the source. Still, it is in my opinion and experience much better to have it mixed inside the document. It makes it much easier to reason locally on what the presentation will look like.

Attaching metadata is done very similarly to both pandoc's markdown and djot.

Metadatas (also called attributes) are enclosed in curly braces: ``{}``. We can attach metadata to two kind of document parts: blocks (such as paragraphs, code blocks, title, definitions, ...) and inlines (such as words or group of words, code spans, links, images, ...).

Block metadata
~~~~~~~~~~~~~~

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
~~~~~~~~~~~~~~~

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
---------------------------------

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

Key-value attributes are defined using an equal sign (``=``). They need a key, and a value. If the value contains spaces or other dubious characters, they should be enclosed in quotes. The quotes are not part of the value of they key attributes! In the example above, the key ``up-at-unpause`` is given value ``title1``, while the key ``exec-at-unpause`` is given the value ``script1 scrip2``.

Some attribute can be used both as a flag attribute and as a key-value attribute.

List of classes
~~~~~~~~~~~~~~~

- Theorem
- Definition
- ...

List of attributes
~~~~~~~~~~~~~~~~~~

- pause
- exec-at-unpause

Custom scripts
~~~~~~~~~~~~~~

Can improve your presentation a lot!


.. code-block:: markdown

		{#script-id}
		```slip-script
		console.log("test")
		```

