Anatomy of a Slipshow presentation
==================================

In this page, the goal is to give a precise idea of how a Slipshow presentation is constructed, without bothering with unnecessary details. It consists of an explanation, so you won't get your hand dirty here! But it helps a lot to understand the picture. The tutorial is a more hands-on introduction, if that is what you are looking for.

Let's start with a concrete example. We'll use this simple presentation as a running example. Here it is:

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
   - ...

What do we have here? On the left, you can see some regular textual content. On the right is the Slipshow presentation that was generated from the text on the left.

This brings us to the first important learning: **Slipshow is a tool that transforms textual content into a presentation**. This process is called *compilation*, and the textual content is often called the *source file*.

Before continuing to read, you can tinker with the presentation above. First, click on the rendered presentation and go forward and backward by pressing the arrows key. During a presentation, you can also annotate the screen. Try that: while the presentation is focused, press ``p`` and use your mouse to draw.

You can also modify the rendered presentation by clicking on the textual content, and editing it! You can try to figure out the syntax from the example and your modifications, but we are going to clarify that very shortly.

The flow of content, and the flow of actions
--------------------------------------------

In most presentations, one can distinguish two distinct parts. One is the static content of the presentation: the set od title, blocks, bullet items and so on, and where they all belong. The other one is the dynamic content: *when* do we change slides? At which point do we show this bullet point?

The source file has to contain both information, for the compiler to be able to create the presentation from it. Let's go back to our example, and isolate each kind:

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
   - ...

And the dynamic content:

.. code-block::

   {pause}

   {up=many}

We are first going to discuss each part separatly, and then how (and why) we combine them in a single source file!

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
   - ...

Those familiar with the Markdown syntax may have recognized it. It is a widely spread syntax for describing documents: For instance, the ``#`` character allows to introduce a title. Which is why ``What is Slipshow`` is rendered as a title!

The Markdown syntax tries to be natural to write, and easy to read. For instance, a list is made simply by prefixing each item with a dash and a space, more or less just like one would naturally do. Beware that this goal forces to introduce some corner-cases and footguns into the syntax. You can find an overview of the `Markdown syntax <https://commonmark.org/help/>`_.

However, the block above has more than Markdown syntax. The parts that are inside curly braces, ``{...}``, may be new to you. This is how you introduce *metadata*: some information that won't be directly displayed, but that will influence the presentation in some ways.

Metadata can attached to a block. This is the case here: The id ``many`` is given to the paragraph that follows ``{#many}``, and the class ``block`` is given to the bullet list ``{.block}``. The class ``block`` is the reason that in the rendering, the list in in a block.

Note that their is no forced discontinuity in the flow of content, compared to what the slide model is giving us.

The dynamic content
-------------------

Let's now focus on the dynamic content.

.. code-block::

   {pause}

   {up=many}

This is the list of actions to be executed. The first one is the ``pause`` action, and the second one is ``up`` action, and it is given some arguments: ``many``.

The actions will be executed one by one, when the speaker press the next button (the right arrow, down arrow, space bar, ...). So this presentation starts at step 0, executes the ``pause`` action at the second step, and the ``up`` action at the second.

If you have tried running through the presentation, you probably have an idea of what these actions do. ``pause`` initially hides what follows, and displays it when executed. ``up`` moves the sliding window such that the target element is at the top of the view. Note that you can include multiple actions in a single step!

Reconciliating the two contents
-------------------------------

One could imagine writing the static and dynamic contents separately, possibly one in each file. Actually, this is possible in Slipshow!

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
   - ...

and

.. code-block::

   {pause=id}

   {up=many}

Note that each is read from top to bottom, making it fit for merging them in a single file. And it has many advantages!
First, for readability, it is good to have some sort of locality: when the actions are located close to the static content visible on screen when they are executed.

Moreover the actions often needs an argument. If they don't have one, but are attached to a specific block, they can be given a default argument! This is how ``pause`` does not need an argument.

So, what to take out from this? Maybe, mostly that most of your presentation will have the actions and the content close together, but you *can* break this, and order the actions in any way you want. You'll probably just need to use an identifier to refer to another element for the action to apply.
