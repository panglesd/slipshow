.. _anatomy:

Anatomy of a Slipshow presentation
==================================

The goal of this page is to give you a clear idea of how a Slipshow presentation is constructed, without going into unnecessary details. It's just an explanation, so you won't need to get your hands dirty yet, but it should help you to understand the big picture. `The tutorial <tutorial>`_ is a more hands-on introduction, if that is what you are looking for.

Let's start by using this simple presentation as an example, and build on it:

.. slipshow-example::

   # What is Slipshow?

   Slipshow is a presentation tool that brings back good things from blackboard presentations.

   {pause}

   {#many}
   And there are many!

   {.block up=many}
   - Interactivity
   - Continuity
   - Pacing
   - …

What do we have here? On the left, we have some regular plain-text content. On the right is the Slipshow presentation that was generated from the text on the left.

This brings us to the first important lesson: **Slipshow is a tool that transforms (or *renders*) textual content into a presentation**. This process is called *compilation*, and the textual content is often called the *source file*.

Before continuing, you can tinker with the presentation above. First, click on the rendered presentation on the right, and go forward and backward through the sequence by pressing the arrow keys. While you're showing a presentation you can also annotate the screen; try it! While the presentation is focused, press :kbd:`p` and then use your mouse to draw on it.

You can also modify the rendered presentation by clicking on the textual content, and editing it! You can try to figure out the syntax from the example and your modifications, but we are going to clarify that very shortly.

The flow of content, and the flow of actions
--------------------------------------------

Most presentations can be divided into two distinct parts. One is the static content of the presentation: the set of titles, blocks, bullet points and so on, where they all belong, and in what order they should appear. The other one is the dynamic content: *when* do we change slides? At which point do we show this bullet point?

A Slipshow source file has to contain both kinds of information for the compiler to be able to create the presentation from it. Let's go back to our example, and isolate each kind:

Here is the static content:

.. code-block::

   # What is Slipshow?

   Slipshow is a presentation tool that brings back good things from blackboard presentations.

   {#many}
   And there are many!

   {.block}
   - Interactivity
   - Continuity
   - Pacing
   - …

And the dynamic content:

.. code-block::

   {pause}

   {up=many}

We are first going to discuss each part separately, and then how (and why) we combine them in a single source file!

The static content
------------------

Let's first recall the static content of our example:

.. code-block::

   # What is Slipshow?

   Slipshow is a presentation tool that brings back good things from blackboard presentations.

   {#many}
   And there are many!

   {.block}
   - Interactivity
   - Continuity
   - Pacing
   - …

Those familiar with Markdown syntax may have recognized it: it is very commonly used syntax for applying basic formatting to documents while still leaving them human-readable. For instance, the ``#`` character  introduces a title, which is why ``What is Slipshow`` is rendered as a title.

Markdown's syntax tries to be natural to write, and easy to read. For instance, a list is made simply by prefixing each line item with a dash and a space, more or less like one would do naturally. This idealistic goal introduces some corner-cases and `footguns <https://en.wiktionary.org/wiki/footgun>`_ into the syntax that have mostly been built into a consistent, standardised flavour of Markdown called *CommonMark*. You can find an overview of `Markdown syntax <https://commonmark.org/help/>`_ on the CommonMark site.

However, the example above contains more than Markdown syntax, specifically, the parts that are inside curly braces, ``{…}``. This is how you introduce *metadata*: information that won't be displayed directly, but that will influence or structure the presentation in some way.

Metadata can attached to a block. This is the case here: ``{#many}`` assigns the ID ``many`` to the paragraph that follows (so that you can refer to it from elsewhere), and the ``block`` class is assigned to the bullet list that follows using ``{.block}`` (note that leading ``.``). The ``block`` class is the reason that the list appears as a block in the rendered version.

Note that there is no discontinuity in the flow of content, compared to what the traditional slide model gives us.

The dynamic content
-------------------

Let's now focus on the dynamic content.

.. code-block::

   {pause}

   {up=many}

This is the list of actions to be executed. The first one is the ``pause`` action, and the second one is ``up`` action, and it is given some arguments: ``many``.

The actions will be executed one by one, when the speaker presses the next button (the right arrow, down arrow, space bar, …). So this presentation starts at step 0, executes the ``pause`` action as the first step, and then the ``up`` action as the second.

If you have tried running through the presentation, you probably have an idea of what these actions do. ``pause`` initially hides what follows, and displays it when executed. ``up`` moves the sliding window so that the target element is at the top of the view. You can include multiple actions in a single step!

Reconciling the two contents
----------------------------

One could imagine writing the static and dynamic contents separately, possibly each in its own file. This is actually possible in Slipshow, like this:

.. code-block::

   # What is Slipshow?

   Slipshow is a presentation tool that brings back good things from blackboard presentations.

   {#id}

   {#many}
   And there are many!

   {.block up=many}
   - Interactivity
   - Continuity
   - Pacing
   - …

and

.. code-block::

   {pause=id}

   {up=many}

Note that each is read from top to bottom, and they can be merged into a single file — and the single file approach has many advantages!
First, for readability, it is good to have some sort of locality: putting the actions close to the content that's visible on screen when they are executed.

Moreover, actions often need an argument or two. If they don't have one, but are attached to a specific block, they can be given a default argument; this is why ``pause`` does not need an argument.

So, what to take away from this? At least to begin with, most of your presentations will keep the actions and the content close together, but it's worth knowing that you *can* break them up if you like, and order the actions in any way you want. You'll need to use identifiers to give an action a target to apply to, but that's a topic for a more applied tutorial.
