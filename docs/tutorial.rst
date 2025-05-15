Tutorial
========

This tutorial assumes you have access to the slipshow compiler. If you are only
interested in trying out slipshow before deciding to install it (or not), you
can use the `sliphub editor <https://sliphub.choum.net/new>`_: it requires no installation
on your computer, nor to create any account!

If you do want to use slipshow, we recommand completing the
:ref:`getting-started` part of the document.

.. contents:: Outline of the tutorial
   :local:
   

Introduction
-----------------

Slipshow is a compiler from a source file to a source language to a slipshow
presentation, so you simply write a text file to describe your
presentation. This makes it portable, lightweight and lets you use your favorite
text editor instead of forcing you into one. It has also drawbacks: it can be
less visual than other solutions such as "power-point" style presentations.

When you turn your source file into a presentation (you *compile* the
presentation), the file created is actually an html file: the format used to
describe websites. So, even if it is a local file, you need to open it with a
web browser with javascript enabled: most web browsers will work. An important
thing to know is that (unless special setup) the file is fully self-contained:
it can be viewed offline, and if you want to send your presentation to someone,
you just need to send them the file. It is also highly portable: it will work on
any OS with a web browser (virtually all of them!).

In this tutorial, you will create your first slipshow presentation. It is
entirely self-contained, and introduces both the usage, the syntax and the
different features of slipshow. Once you are familiar with the basics, for a
complete overview of each of these, you should refer to the reference: the
:ref:`Syntax reference`.

..
   Writing slips should not differ too much from writing beamer presentation, when not using any of the advanced functionalities: there an delimiters for . The syntax is different, and there are 
..
   The easiest way is to include the library using a CDN, this is the option we choose to use in this tutorial for its simplicity. However, in this case you will not be able to display your slips without internet access. To use a local version, see :ref:`getting-started`.

A minimal example
-----------------

We start by considering a simple but complete example. This allows us to cover
the basic usage of the tools, the basic syntax, and the basic features of
slipshow. The next parts of the tutorial will build on this example to explain
the more advanced workflows!

To start, copy the following lines in a file, named for instance
``prime-numbers.md``:

.. code-block:: markdown

   # Prime numbers

   What is a prime number?

   {pause}

   {.definition}
   A **prime number** is an integer divisible by exactly two integers: 1, and itself.


.. note::

   The extension of the file (``.md``) is for ``markdown``. Many editors will
   open files with such extension in a special mode that will help you read and
   write it. Slipshow's syntax is an extension of markdown.

Compiling and viewing your presentation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The file that we just created is the *source* for a minimal prime-numbers. In
order to get the presentation itself, we need to *compile* it, using the
``slipshow`` tool.

This step depends on the way you have access to the slipshow compiler.

.. tabs::

   .. tab:: In VS Code

      In the command palette (``Cmd + Maj + P``), write ``Compile slipshow``. This will create a file in the same directory, with the same name but the ``.html`` extension.

      To view this file, opening it in a browser is sufficient! However, the file won't automatically update to new modifications on your source file. For this, open the command palette again and this time, write ``Preview slipshow``. This will open a preview of the presentation, which will automatically update to the newest changes!

      In conclusion: use the preview command when writing your presentation, and use the compile one when your presentation is finished!

   .. tab:: Using the binary

      In a terminal, issue the following command:

      .. code-block:: shell

		$ slipshow serve prime-numbers.md
		Visit http://localhost:8080 to view your presentation, with auto-reloading on file changes.

      This ``serve`` command creates a file with the same name as the input
      name, but a different extension: ``prime-numbers.html``. The ``.md`` file
      is the one you'll use to modify the presentation, and the one you'll share
      with another author of the presentation. The ``.html`` file is the one
      you'll use to view or do your presentation, or to share with someone
      interested in viewing the presentation.

      Moreover, the ``flag`` command will propagate any saved changes in the
      input file, and "live-reload" the presentation served at the address
      ``http://localhost:8080``. It is very useful when writing your
      presentation. When you only want to generate the html file once, use
      ``compile`` instead.

   .. tab:: In the slipshow editor

            On the right, you have a preview of your presentation: very useful when writing it! However, when your presentation is ready, you will want to turn it into a file that you can open in the browser.

            Just click on the ``Compile`` button on the top bar. This will ask you the compiled file name. Then, whenever your source file and compiled file become out of sync, the color of the compiled file will turn red!

   .. tab:: In sliphub

            Your file is saved on the server live!

            On the right, you have a preview of your presentation: very useful when writing it! However, when your presentation is ready, you might want to turn it into a local file that you can open in the browser.

            To locally save a compiled source file, click on the ``Download
            presentation`` button.

            You can also use the "presentation link" which allow to share a "readonly" version of your presentation!

On the slipshow preview, you should see the familiar format for
slide-based presentations (4:3 rectangle with black borders). Click on it to be
sure you have the window focused, and hit the right arrow key (or equivalently,
the down-arrow key) to step through the presentation! Right now, it has only two
steps: the initial one, and the last one.

Try to make a modification in ``prime-numbers.md`` and save the file. The
preview should refresh automatically with the new content!

The syntax used
~~~~~~~~~~~~~~~~

Slipshow uses an extension of Markdown for its main syntax. So, knowing Markdown is a prerequisite to using slipshow.
Fortunately, Markdown is very simple! And is already widely used. So instead of explaining the markdown syntax in this tutorial, I'll link to some great resources to learn Markdown, and only explain the additions:

The `Learn Markdown in 60 seconds <https://commonmark.org/help/>`_ is from CommonMark, the organization that proposed a well-defined specification for Markdown. They also have a 10-minute tutorial to learn but also train!

The slipshow syntax is defined in :ref:`Syntax reference`. In this tutorial, let's only focus on the syntax used in the example.

Pauses
""""""

The fifth line is the first one that is not regular markdown:

.. code-block:: markdown

   {pause}

This line won't appear as is in the rendered presentation. In fact, any
content inside curly braces ``{...}`` is considered "metadata" and will be
interpreted in specific ways, but not displayed in the presentation.

The purpose of this line is to inform the slipshow engine that the presentation
should "pause" here. Indeed, when opening the presentation, only the title and
the first paragraph were shown. The rest of the presentation was shown only
after the "right" key was pressed.

Blocks
""""""

Following the ``{pause}`` keyword, we have the following content:

.. code-block:: markdown

   {.definition}
   A **prime number** is a number divisible by exactly two integers: 1, and itself.

The meaning should be clear from the rendered presentation: this is a
"definition" block. As you can see, we use the "metadata" syntax once again: the
``{.definition}`` part is not rendered, but is used to describe the content. In
this case, there is a ``.`` followed by a word: such syntax is used for add a
"class" to an element, an information which is used only to alter the rendering
of an element.

There are several classes available. To describe blocks, in addition to the
"definition" block, you can chose from ``.theorem``, ``.proof``, ``.alert``, and
``.block``.

.. note::

   Blocks support the display of a title. You can provide the title in the
   metadata: ``{.definition title="Prime numbers"}``. Try it in the example!


If your block includes multiple paragraphs or elements, just indent all those
elements using ``>``. For instance, try the following in the examples:

.. code-block:: markdown

		 {.definition}
		 > A **prime number** is a number divisible by exactly two integers: 1, and itself.
		 >
		 > We consider 1 not to be a prime number, as it is divisible only by one integer.

Your presentation as a papyrus
------------------------------

In the minimal example, we haven't yet touched the *core* of slipshow. But we
are close to that!

Let's expand our basic example with the fact and proof that there are infinitely
many prime numbers. This is one of the first important fact to know!

Append the following lines to the example file. (If you are dissatisfied with the
proof, feel free to improve it 🙂.)

.. code-block:: markdown


   {pause}

   {.theorem}
   There are infinitely many prime numbers.

   {pause .proof}
   > Suppose there are finitely many prime numbers.
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
   > **Therefore, there must exists infinitely many prime numbers.**

Let's look at the updated rendering of the presentation: What you see is quite
disapointing. There is too many content for the space available, and the last
part of the proof overflows and is invisible. Most presentations would solve
this problem by creating a new slide, but slipshow does it very differently,
which is what makes it unique!

The problem of uncovering new content
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recall the problem here. There is too much content for the space we have: the
proof of the infinity of prime numbers overflow through the bottom end!

The usual answer from traditional slideshow programs are to create a new slide
to hold the new content. But that does not come without problems. For instance,
what to put in this new slide? Obviously, we don't want to put *only* the
overflown content in the new slide: this content should be seen in some context,
that you want to have on screen.

So, one way would be to duplicate some content from the previous slide on the
second slide. This works reasonably well, but is often difficult to follow for
the viewer: it takes cognitive load to distinguish between what is new and what
is just duplicated content in a new slide.

Moreover, it is also a problem for the author: duplicated content means
duplicated work when, for instance, rewording the duplicated content.

..
   - **Create a new slide**

     When there is no space available, traditional presentations just create a new
     slide, with all free space. But what to put in this new slide? Obviously, we
     don't want to put *only* the overflown content in the new slide: this content
     should be seen in some context, that you want to have on screen.

     So, one way would be to duplicate some content from the previous slide on the
     second slide. This works reasonably well, but is often difficult to follow for
     the viewer: it takes cognitive load to distinguish between what is new and
     what is just duplicated content in a new slide.

     Moreover, it is also a problem for the author: duplicated content means
     duplicated work when, for instance, rewording the duplicated content.

..
   - **Put less content in the slide**.

     This is usually a good thing, not to try to put too much content in a
     slide. However, there are situations (specifically targetted by slipshow)
     where you don't want to compromise the content for brevity. For instance, you
     are making a complex presentation on some topics, and want all proofs to be
     self-contained.


..
   Create a file named ``myPresentation.html`` and copy-paste the minimal example.

Slipshow's way
~~~~~~~~~~~~~~

Slipshow's solution is to, instead of clearing the whole screen and duplicating
some content, just "scroll" the window down to get more space for the new
content, hiding only what you do not need anymore!

Let's focus on our specific case here. We don't have enough space for the whole
proof, but we do not need to see the presentation title, nor the (kind of
useless) rhetorical question. However, we do want to keep the "prime number"
definition, as long as possible, and the theorem statement as well, of course.

So what we want to do is to "scroll" (I also like the idea of a papyrus being
unrolled), until the definition is at the top of the screen. We need two things for that:

1. Be able to refer to a part of your presentation (in our case, the
   definition),
2. Tell the slipshow engine *when* to move the screen (in our case: when we
   start displaying the proof),
3. Tell the slipshow engine *where* to move the screen (in our case: such that
   the definition is on top).

Unsurprisingly, all these information are put in the metadatas parts of slipshow
syntax: everything enclosed in ``{}``.

Be able to refer to a part of your presentation
"""""""""""""""""""""""""""""""""""""""""""""""

For the first point, slipshow uses a system of ids. An id is just a string
without space, that must be unique amongst all ids. In order to assign an id to
a block, one must add the id prepended with a ``#`` inside the metadata of the
block. For instance, let's add the ``prime-def`` id to the definition. The
source should look like this now:

.. code-block:: markdown

   		 {.definition #prime-def}
		 A **prime number** is a number divisible by exactly two integers: 1, and itself.

Tell the engine *when* to move the screen
"""""""""""""""""""""""""""""""""""""""""

For the second point, we use the ``at-unpause`` metadata kind. Such metadata
should only be grouped with a ``pause`` metadata. It says that a specific action
must be taken when stepping through this pause.

Tell the engine *where* to move the screen
""""""""""""""""""""""""""""""""""""""""""

For the third point, slipshow has several commands to move the screen. In our
case, we want to put something on top of the screen, so we use ``up`` keyword.

Putting everything together
"""""""""""""""""""""""""""

So, we want to add ``up-at-unpause=prime-def`` to the
pause associated to the proof. The modified source should look like this:

.. code-block:: markdown

   {.definition #prime-def}
   A **prime number** is a number divisible by exactly two integers: 1, and itself.

   [...]

   {pause .proof up-at-unpause=prime-def}
   > Suppose there are finitely many prime numbers.
   > [...]

Try the rendered version of this new source: by getting rid of anything not
useful, there is enough space in the screen to display the definition, theorem
statement and whole proof!

The source is still readable, the flow is not broken, and the presentation is
easy to follow for the viewer.

.. note::

   The main instructions to move the window are ``up`` to put some element on
   top of the screen, ``down`` to put it at the bottom, and ``center`` to center
   it.

   If no id is given, the instruction is considered to apply on the element
   itself. For instance, ``down-at-unpause`` without id is a useful command,
   that we could have used on the ``proof`` element.

.. note::

   It is not always best to remove everything that you don't need. For instance,
   in the example above, suppose that you continue by giving an example of a
   very big prime number. Technically, you could start fresh, the example does
   not *need* the proof to be on screen. However, for any viewer that is a
   little bit late, it is very good to keep at least the end of the proof
   visible, in order to let them finish their note-taking and catch up with the
   presentation.


Making your presentation live
-----------------------------

The previous sections cover most of the first phase of making a presentation:
the preparation. Slipshow has also several important features regarding the
presentation in itself!

Writing on the screen
~~~~~~~~~~~~~~~~~~~~~

One of the design goal of slipshow is to make digital presentations "less bad"
compared to the blackboard ones.

One of the great features of blackboards is that you can write on them while
explaining, doodle, make arrows all over the place. To try to do something
similar, the slipshow rendering engine allows you to write on your presentation,
using the tools present on the top left of your presentation.

The best is still to use the shortcuts:

- ``w`` to write,
- ``h`` to highlight,
- ``e`` to erase,
- ``x`` to go back to a normal cursor,
- ``X`` to clear all annotations.

Add the following content to your presentation, which creates a table in
slipshow, following markdown "GFM" syntax:

.. code-block::

   |1|2|3|4|5|6|7|8|9|10|
   |11|12|13|14|15|16|17|18|19|20|
   |21|22|23|24|25|26|27|28|29|30|
   |31|32|33|34|35|36|37|38|39|40|
   |41|42|43|44|45|46|47|48|49|50|
   |51|52|53|54|55|56|57|58|59|60|
   |61|62|63|64|65|66|67|68|69|70|
   |71|72|73|74|75|76|77|78|79|80|
   |81|82|83|84|85|86|87|88|89|90|
   |91|92|93|94|95|96|97|98|99|100|

and explain the Eratosthenes schema by executing it live!

Starting animations
~~~~~~~~~~~~~~~~~~~

Many concepts are much easier to understand with animations. I have always been
impressed at how scientific popularization video can make very difficult
concepts much easier to understand, and also much more fun to learn. There is no
point in not using this in our presentations!

Altough slipshow itself does not provide any support for defining animations, it
allows you to embed a video, or use any javascript library. For a scripted start
and stepping of your animation, you can use the ``exec-at-unpause`` attribute,
combined with the special ``slip-script`` codeblock!

Here is a minimal example of an Eratosthenes animation. It is very badly written,
in JS/CSS/HTML, so you need some basic skills on these to understand it, but you
can use libraries to make it less tedious.

.. code-block:: markdown

   {#container}

   {pause exec-at-unpause}
   ```slip-script
   let d = document.querySelector("#container");
   d.style="display: grid; grid-template-columns: repeat(10, auto)";
   for(i=1; i<=50 ; i++) {
     let e = document.createElement("div")
     e.style = "border: 1px solid black; padding: 5px ; margin: 5px";
     e.textContent = i;
     d.appendChild(e)
   }
   ```

   {pause exec-at-unpause}
   ```slip-script
   let array = document.querySelectorAll("#container > *");
   function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
   }
   async function do_(start, w) {
     array[start - 1].style.background="green";
     await sleep(w);
     for(j = start * 2 ; j <= 50 ; j += start) {
       await sleep(125);
       array[j-1].style.background="red";
     }
   }
   slip.do_ = do_
   do_(2, 50)
   ```

   {pause exec-at-unpause}
   ```slip-script
   slip.do_(3, 100)
   ```


Using the table of content
~~~~~~~~~~~~~~~~~~~~~~~~~~

Press ``t`` during a presentation to open the table of content, with fast jump
to any part of your presentation!

Moving freely
~~~~~~~~~~~~~

During a presentation, it is important to not be too tied to the original
program. You can move the window freely, using the ``i``, ``j``, ``k`` and ``l``
keys. Change the "zoom" factor using the ``z`` and ``Z`` keys.
