Creating your first presentation
================================

Thanks to the editors and preview embedded in this page, this tutorial does not *require* you to have access to the Slipshow compiler on your machine. However, we encourage you to have it, to not just read, but actually create the presentation this tutorial is describing. It is even better if you modify it to make it your own!

.. contents:: Outline of the tutorial
   :local:

Introduction
------------

Slipshow is a compiler that converts a source file to a Slipshow
presentation, so you simply write a text file to describe your
presentation. This makes it portable, lightweight, and lets you use your favorite
text editor instead of forcing you into an unfamiliar one. It also has drawbacks: it can be
less visual than other solutions such as PowerPoint-style presentation tools.

When you compile your source file into a presentation, the file it creates is actually an HTML file, the format used for websites. So, even if it is a local file, you need to open it with a
web browser with JavaScript enabled: most web browsers will work. An important
thing to know is that (unless specially set up) the file is fully self-contained.
It can be viewed offline, and if you want to send your presentation to someone,
you just need to send them the file. It is also highly portable: it will work on
any system with a web browser (virtually all of them!).

In this tutorial, you will create your first Slipshow presentation. It is
entirely self-contained, and introduces both the usage, the syntax and the
different features of Slipshow. :ref:`anatomy:Anatomy of a Slipshow presentation` is a good complementary read.

..
   Writing slips should not differ too much from writing `beamer presentations <https://latex-beamer.com>`_ when not using any of its advanced functionalities.
..
   The easiest way is to include the Slipshow library from a CDN; this is the option we chose for this tutorial for its simplicity. However, in this case you will not be able to display your slips without internet access. To use a local version, see :ref:`getting-started`.

A minimal example
-----------------

We start by considering a simple but complete example. This allows us to cover
using the tools, the basic syntax, and Slipshow's fundamental features.
Later parts of the tutorial will build on this example to explain more advanced features and workflows.

To start, copy the following lines into a file, named (for this example) ``prime-numbers.slp``:

.. slipshow-example::
   :visible: both
   :dimension: 4:3

   # Prime numbers

   What is a prime number?

   {pause}

   {.definition}
   A **prime number** is an integer divisible by exactly two integers: 1, and itself.


.. note::

   The extension of the file (``.slp``) indicates it's a Slipshow source file. If you did not set up your editor to support Slipshow, you might want to use the ``.md`` extension (for ``markdown``): Many editors support markdown out of the box, and Slipshow's syntax is an extension of it.

Compiling and viewing your presentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note::

   If you have already :doc:`set up your editor <editor-setup>`, the compilation
   and preview at ``http://localhost:8080`` will be handled by your editor; you
   don't need to type the command below.

The file we just created is the *source* for a minimal prime-numbers presentation. In order to turn it into the presentation itself, we need to *compile* it, using the ``slipshow`` tool.

In a terminal, issue the following command:

.. code-block:: shell

   $ slipshow serve prime-numbers.slp
   Visit http://localhost:8080 to view your presentation, with auto-reloading on file changes.

This ``serve`` command creates a file with the same name as the input
name, but a different extension: ``prime-numbers.html``. The ``.slp`` file
is the one you'll use to modify the presentation, and the one you'll share
with another author of the presentation. The ``.html`` file is the one
you'll use to view or do your presentation, or to share with someone
interested in *viewing* the presentation.

Moreover, the ``serve`` command will propagate any saved changes in the
input file, and "live-reload" the presentation served at the address
``http://localhost:8080``, which you can open in your web browser. This is very useful when writing your
presentation. When you only want to generate the HTML file once, use
``compile`` instead.

On the Slipshow preview, you should see the familiar format for
slide-based presentations (a 4:3 rectangle with black borders). Click on it to be
sure you have the window focused, and press the :kbd:`Right arrow` key (or equivalently,
the :kbd:`Down arrow` key) to step through the presentation! Right now, it has only two
steps: the initial one, and the last one.

Try to make a modification in ``prime-numbers.slp`` and save the file. The
preview should refresh automatically with the new content!

Also, type :kbd:`s`: this opens the speaker view, with a timer, notes you might
want to add, and a synced view of the presentation.

.. warning::

   The speaker view is disabled in the Slipshow previews embedded in this
   tutorial.

Slipshow syntax
~~~~~~~~~~~~~~~

Slipshow uses an extension of Markdown for its main syntax, so having already seen Markdown will give you a head-start with Slipshow.
Fortunately, Markdown is very simple, and is very widely used. I'll link to some great resources to learn Markdown, but you can continue with this tutorial first and come back to them later.

The `Learn Markdown in 60 seconds <https://commonmark.org/help/>`_ is from CommonMark, the organization that proposed a well-defined (and widely followed) specification for Markdown. They also have a 10-minute tutorial to learn and also further training materials. The `Markdown Guide <https://www.markdownguide.org/>`_ is a more complete reference, with a lot of examples.

The Slipshow markup is defined in :doc:`slipshow-syntax`. In this tutorial, let's only focus on the syntax used in the example.

Pauses
""""""

The fifth line is the first one that is not regular markdown:

.. code-block:: markdown

   {pause}

This line won't appear as-is in the rendered presentation. In fact, any
content inside curly braces ``{...}`` is considered "metadata" and will be
interpreted in specific ways, but not displayed in the presentation.

The purpose of this line is to inform the Slipshow engine that the presentation
should stop and wait here. Indeed, when opening the presentation, you may have noticed that only the title and the first paragraph were shown; the presentation only continued after the :kbd:`Right arrow` key was pressed.

Blocks
""""""

Following the ``{pause}`` keyword, we have the following content:

.. code-block:: markdown

   {.definition}
   A **prime number** is a number divisible by exactly two integers: 1, and itself.

The meaning should be clear from the rendered presentation: this is a
"definition" block. As you can see, we use the "metadata" curly-bracket syntax once again: the ``{.definition}`` part is not rendered, but is used to modify the appearance of the content that immediately follows it.
In this case, there is a ``.`` followed by a word: such syntax is used to add a
"class" to an element, which is used to alter the rendered appearance of an element, for example its size, font, colour, or other display attributes.

There are several predefined block classes available. In addition to the
``.definition`` block, you can chose from ``.theorem``, ``.proof``, ``.alert``, and ``.block``.

.. note::

   Blocks support the display of a title. You can provide the title in the
   metadata, for example ``{.definition title="Prime numbers"}``. Try it in the example!

If your block includes multiple paragraphs or elements, just indent all those
elements using ``>``. For instance, try the following in the examples:

.. code-block:: markdown

    {.definition}
    > A **prime number** is a number divisible by exactly two integers: 1, and itself.
    >
    > We consider 1 not to be a prime number, as it is divisible only by one integer.

Your presentation as a papyrus
------------------------------

In this minimal example, we haven't yet touched the *core* of Slipshow's typed
presentations. But we are close to that!

Let's expand our basic example with the fact and proof that there are infinitely
many prime numbers! Slipshow supports mathematical formulae using `LaTeX syntax <https://www.latex-project.org/help/documentation/>`_,
so we can write a proof that is rigorous, readable, and technically correct.

Append the following lines to the example file. (If you are dissatisfied with the
proof, feel free to improve it 🙂.)

.. code-block:: markdown

   {pause}

   {.theorem}
   There are infinitely many prime numbers.

   {pause .proof}
   > Suppose there are a finite number of prime numbers.
   >
   > Let's write $p_0, p_1, \dots, p_{n-1}$ a list of all prime numbers. We define:
   >
   > ```math
   > P = \prod_{i=0}^{n-1}p_i, \quad
   > N = P + 1.
   > ```
   >
   > {pause}
   >
   > Let $p$ be a prime divisor of $N$. We claim that:
   >
   > ```math
   > \forall i, p\neq p_i
   > ```
   > {pause}
   > Indeed,
   >
   > ```math
   > p \text{ divides } N \land\ p\text{ divides } P \implies p\text{ divides } 1
   > ```
   >
   > So $p$ is a prime that is not part of the $p_i$, a contradiction. {pause}
   > **Therefore, there must be infinitely many prime numbers.**

.. slipshow-example::
   :visible: presentation
   :dimension: 4:3

   # Prime numbers

   What is a prime number?

   {pause}

   {.definition}
   A **prime number** is an integer divisible by exactly two integers: 1, and itself.

   {pause}

   {.theorem}
   There are infinitely many prime numbers.

   {pause .proof}
   > Suppose there are a finite number of prime numbers.
   >
   > Let's write $p_0, p_1, \dots, p_{n-1}$ a list of all prime numbers. We define:
   >
   > ```math
   > P = \prod_{i=0}^{n-1}p_i, \quad
   > N = P + 1.
   > ```
   >
   > {pause}
   >
   > Let $p$ be a prime divisor of $N$. We claim that:
   >
   > ```math
   > \forall i, p\neq p_i
   > ```
   > {pause}
   > Indeed,
   >
   > ```math
   > p \text{ divides } N \land\ p\text{ divides } P \implies p\text{ divides } 1
   > ```
   >
   > So $p$ is a prime that is not part of the $p_i$, a contradiction. {pause}
   > **Therefore, there must be infinitely many prime numbers.**

When we look at the updated rendering of the presentation, it is quite
disappointing. There is too much content for the space available, so the last
part of the proof overflows the screen and is invisible. Most presentations would solve
this problem by creating a new slide, but Slipshow does it very differently,
which is what makes it unique!

.. note::

   Slipshow supports several ways of grouping. Instead of ``>``, you can enclose the proof with ``---``. In this case, it would become:

   .. code-block::

      {.theorem}
      There are infinitely many prime numbers.

      {pause .proof}
      ---
      Suppose there are finitely many prime numbers.
      [...]
      **Therefore, there must exists infinitely many prime numbers.**
      ---

The problem of uncovering new content
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recall the problem here. There is too much content for the space we have: the
proof of the infinity of prime numbers falls off the bottom of the slide!

The usual solution in traditional slideshow programs is to create a new slide
to hold the overflowing content, but that does not come without problems. For instance,
what to put in this new slide? Obviously, we don't want to put *only* the
overflowing content in the new slide as it doesn't make much sense by itself; it needs to have some context
that remains on screen.

So, one way would be to duplicate some content from the previous slide on the
second slide. This works reasonably well, but is often difficult to follow for
the viewer: it takes cognitive load to distinguish between what is new and what
is just duplicated content in a new slide.

Moreover, it is also a problem for the author: duplicated content means
duplicated work when, for instance, rewording the duplicated content.

..
   - **Create a new slide**

     When there is no more space available, traditional presentation tools just create a new
     slide, with all free space. But what to put in this new slide? Obviously, we
     don't want to put *only* the overflowing content in the new slide: this content
     should be seen in some context that remains on screen.

     So, one way would be to duplicate some content from the previous slide on the
     second slide. This works reasonably well, but is often difficult to follow for
     the viewer: it takes cognitive load to distinguish between what is new and
     what is just duplicated content in a new slide.

     Moreover, it is also a problem for the author: duplicated content means
     duplicated work when, for instance, rewording the duplicated content.

..
   - **Put less content in the slide**.

     This is usually a good thing: try to say more with less.
     However, there are situations (specifically targeted by Slipshow)
     where you don't want to compromise the content for brevity. For instance, if you
     are making a complex presentation on a topic, and want all proofs to be
     self-contained.

..
   Create a file named ``myPresentation.html`` and copy-paste the minimal example into it.

The Slipshow way
~~~~~~~~~~~~~~~~

Slipshow's solution is, instead of clearing the whole screen and duplicating
some content, to just "scroll" the window to make more space for the new
content, hiding only what you no longer need!

Let's focus on our specific case here. We don't have enough space for the whole
proof, but we do not need to see the presentation title, nor the (somewhat
useless) rhetorical question. However, we do want to keep the "prime number"
definition, as long as possible, and the theorem statement as well, of course.

So what we want to do is to "scroll" (I also like the idea of a papyrus being
unrolled), until the definition is at the top of the screen. We need three things for that:

1. To refer to a specific part of a presentation (in our case, the definition),
2. To tell the Slipshow engine *when* to move the screen (in our case: when we
   start displaying the proof),
3. To tell the Slipshow engine *where* to move the screen (in our case: so that
   the definition is on top).

Unsurprisingly, all of this information can be put into the curly-bracketed metadata parts of Slipshow's
syntax.

Refer to a part of a presentation
"""""""""""""""""""""""""""""""""

For this first feature, Slipshow uses IDs. An ID is just a string
(without any spaces), that must be unique amongst all IDs. In order to assign an ID to a block,
add the ID prepended with a ``#`` inside the metadata of the block.
For instance, let's add the ``prime-def`` id to the definition. The
source should look like this now:

.. code-block:: markdown

        {.definition #prime-def}
        A **prime number** is a number divisible by exactly two integers: 1, and itself.

Tell the engine *when* to move the screen
"""""""""""""""""""""""""""""""""""""""""

For the second point, we add an "action" to the metadata; actions like this
should only be grouped with a ``pause`` metadata. They effectively describe
what's going to happen _after_ the pause. Here we are going to use ``up`` as our action.

Tell the engine *where* to move the screen
""""""""""""""""""""""""""""""""""""""""""

The third point really joins the previous two together. Saying "up" isn't very precise, so we need to provide the ``up`` action with a specific target to move to, in this case ``prime-def``, the ID that we defined earlier.

Putting everything together
"""""""""""""""""""""""""""

We need to add ``up=prime-def`` to the pause associated with the proof. The modified source should look like this:

.. code-block:: markdown

   {.definition #prime-def}
   A **prime number** is a number divisible by exactly two integers: 1, and itself.

   [...]

   {pause .proof up=prime-def}
   > Suppose there are a finite number of prime numbers.
   > [...]

.. slipshow-example::
   :visible: presentation
   :dimension: 4:3

   # Prime numbers

   What is a prime number?

   {pause}

   {.definition #prime-def}
   A **prime number** is an integer divisible by exactly two integers: 1, and itself.

   {pause}

   {.theorem}
   There are infinitely many prime numbers.

   {pause .proof up=prime-def}
   > Suppose there are a finite number of prime numbers.
   >
   > Let's write $p_0, p_1, \dots, p_{n-1}$ a list of all prime numbers. We define:
   >
   > ```math
   > P = \prod_{i=0}^{n-1}p_i, \quad
   > N = P + 1.
   > ```
   >
   > {pause}
   >
   > Let $p$ be a prime divisor of $N$. We claim that:
   >
   > ```math
   > \forall i, p\neq p_i
   > ```
   > {pause}
   > Indeed,
   >
   > ```math
   > p \text{ divides } N \land\ p\text{ divides } P \implies p\text{ divides } 1
   > ```
   >
   > So $p$ is a prime that is not part of the $p_i$, a contradiction. {pause}
   > **Therefore, there must be infinitely many prime numbers.**

Try the rendered version of this new source: by getting rid of anything that's not
useful, we have made enough screen space to display the definition, theorem
statement, and its whole proof!

The source is still readable, the flow is not broken, and the presentation is
easy to follow for the viewer.

.. note::

   The main actions for moving the window view are ``up`` to put some element on
   top of the screen, ``down`` to put it at the bottom, and ``center`` to center
   it vertically.

   If no ID is given, the instruction is considered to apply to the element
   itself. For instance, ``down`` without an ID is a useful command,
   that we could have used on the ``proof`` element.

.. note::

   It is not always best to remove _everything_ that you don't need. For instance,
   in the example above, suppose that you continue by giving an example of a
   very big prime number. Technically, you could start fresh, the example does
   not *need* the proof to be on screen. However, for any viewer that is a
   little bit late, it is very good to keep at least the end of the proof
   visible, in order to let them finish their note-taking and catch up with the
   presentation.

.. note::

   Don't go too fast! The more textual content you have, the slower you should
   go. Think about how long it would have taken you to write all this on a
   whiteboard.

Making your presentation live
-----------------------------

The previous sections cover most of the first phase of making a presentation:
the preparation. Slipshow has also several important features regarding the
presentation in itself!

Using the speaker view
~~~~~~~~~~~~~~~~~~~~~~

You can open the speaker view with the :kbd:`s` keybinding. The speaker view has a
timer and a clock, speaker notes (filled using the ``speaker-note`` action) and
a mirror of your main presentation. It's disabled in the previews in this tutorial.

Writing on the screen
~~~~~~~~~~~~~~~~~~~~~

One of the Slipshow's goals is to make digital presentations "less bad" when compared
to those done on a blackboard.

One of the great features of blackboards is that you can write on them while
explaining, doodle, make arrows all over the place. To try to do something
similar, the Slipshow rendering engine allows you to write on your presentation,
using the tools present on the top left of your presentation.

The best is still to use the shortcuts:

- :kbd:`w` to write,
- :kbd:`h` to highlight,
- :kbd:`e` to erase,
- :kbd:`x` to go back to a normal cursor,
- :kbd:`X` to clear all annotations.

See :doc:`record-tutorial` and :doc:`record-and-replay` for more information on
drawing, and in particular for recording your drawings beforehand and replaying
them during the presentation!

Using the table of content
~~~~~~~~~~~~~~~~~~~~~~~~~~

Press :kbd:`t` during a presentation to open the table of contents, with fast jump
to any part of your presentation!

Moving freely
~~~~~~~~~~~~~

During a presentation, it is important to not be too tied to the original
sequence, for example if someone asks you a question arising from an earlier slide, it's useful to be able to jump to it quickly without having to backtrack through everything.
You can move the window freely, using the :kbd:`i`, :kbd:`j`, :kbd:`k` and :kbd:`l`
keys. Change the "zoom" factor using the :kbd:`z` and :kbd:`Z` keys.

What next?
----------

Congratulations, you've finished the tutorial for typed presentations! There are however many more things to learn:

- Typed presentations are great but parts of your presentation might benefit
  from being handwritten. The :doc:`record-tutorial` explains how to do that.
- We only touched briefly on Slipshow's syntax. When you face new situations, you'll
  need more thorough documentation of Slipshow's features and syntax.
- While basic, predefined actions such as ``pause`` or ``up`` can get you quite a long way,
  if you want more custom animations it is nice to know how to write your own
  scripts.
