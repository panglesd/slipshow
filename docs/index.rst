.. slip-js documentation master file, created by
   sphinx-quickstart on Thu Jan 23 17:03:49 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to slipshow's documentation!
====================================

**Slipshow is a presentation tool that unlocks new ways of presenting.**

Slipshow allows several presentation styles, that can easily be mixed-and-matched. One of them is the traditional slide-based presentation, but the following two are more interesting. I call them "typed presentation" and "drawn presentation".

In a typed presentation, the equivalent of a slide is called a *slip*. Each slip is like a slide, but with no bottom limit. That is, the content can be arbitrarily long! During the presentation, the camera will "scroll" down to reveal the hidden content, following a script given by the presenter!

In a drawn presentation, the content consists of replaying a recorded drawing made by the author. It makes presentation such as the one made by TODO: links 2-minute physics, RSA animate or Suckerpinch much more accessible, and note that there is no need for drawing skill to make such a presentation more didactic, entertaining, more satisfying to create, or just feeling more human.

Slipshow compiles files written in an extension of markdown, to a standalone html file viewable offline in any web browser.

This documentation can be read linearly. It alternates between more in-depth explanations, hands-on tutorial and technical references. If you know what you are looking for, each section tries to be focus and reasonably self-contained, so you can directly go to what you are looking for.

We advise you to start by reading the :ref:`tutorial`. You can also peek at the :ref:`examples`.


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

.. toctree::
   :maxdepth: 1
   :caption: Tutorials

   tutorial
   record-tutorial
   visual-structure

.. toctree::
   :maxdepth: 1
   :caption: Explanations

   anatomy
   actions
   groups-and-layouts
   custom-scripts

.. toctree::
   :maxdepth: 1
   :caption: How to ...

   split-in-multiple-files
   write-your-own-theme
   use-a-carousel
   embed-things
   do-a-slide-based-presentation

.. toctree::
   :maxdepth: 1
   :caption: References

   slipshow-syntax
   attributes-ref
   special-elements
   actions-api
   frontmatter
   shortcuts
   cli

.. toctree::
   :maxdepth: 1
   :caption: Zoo

   examples
   faq
