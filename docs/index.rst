.. slip-js documentation master file, created by
   sphinx-quickstart on Thu Jan 23 17:03:49 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Slipshow's documentation!
====================================

**Slipshow is a presentation tool that unlocks new ways of presenting.**

Slipshow allows several presentation styles that can easily be mixed-and-matched. One of them is the traditional slide-based presentation, but the other two are more unusual.

In a *typed* presentation, the equivalent of a slide is called a *slip*. Each slip is like a slide, but with unlimited height, so the content can be arbitrarily long! During the presentation, the point of view will scroll down to reveal the hidden content, following a script given by the presenter!

A *drawn* presentation replays the author's hand-drawn content. It makes presentations such as the ones made by `minutephysics <https://www.youtube.com/user/minutephysics>`_, `RSA animate <https://www.youtube.com/playlist?list=PL39BF9545D740ECFF>`_, or `Suckerpinch <https://www.youtube.com/watch?v=QVn2PZGZxaI>`_ possible for a live presentation. There is no need for drawing skills to make such a presentation more didactic, more entertaining, more satisfying to create, or just to feel more human than boring PowerPoint™ bullet points.

Slipshow compiles files written in an extension of `Markdown <https://en.wikipedia.org/wiki/Markdown>`_, to a standalone HTML file that's viewable offline in any web browser.

This documentation can be read linearly. It alternates between more in-depth explanations, hands-on tutorial, and technical references. If you know what you are looking for, each section aims to be focused and reasonably self-contained, so you can go directly to what you are looking for.

We advise you to start by reading the tutorials, starting with the :doc:`first <tutorial>`. You can also peek at the :doc:`examples`.

..
   .. slipshow-example::

      Hello this is a test

..
   .. raw:: html

      <div class="running-example">This is a first paragraph.

      This is a second paragraph.
      This is part of the second paragraph.</div>

.. toctree::
   :maxdepth: 1
   :caption: Getting started

   Introduction <self>
   quick-start
   editor-setup
   examples

.. toctree::
   :maxdepth: 1
   :caption: Tutorials

   tutorial
   record-tutorial
   visual-structure
   custom-scripts

.. toctree::
   :maxdepth: 1
   :caption: Explanations

   anatomy

.. toctree::
   :maxdepth: 1
   :caption: How to…

   record-and-replay
   managing-large-presentations
   use-speaker-view
   figures-bit-by-bit
   do-a-slide-based-presentation
   tikz
   manim

.. toctree::
   :maxdepth: 1
   :caption: References

   slipshow-syntax
   attributes-ref
   grouping
   special-elements
   actions-api
   math
   custom-scripts-ref
   frontmatter
   themes
   shortcuts
   cli
   mermaid
