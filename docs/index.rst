.. slip-js documentation master file, created by
   sphinx-quickstart on Thu Jan 23 17:03:49 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to slipshow's documentation!
====================================

.. warning::
   Slipshow is under heavy modifications: it now includes a compiler from markdown to a standalone slipshow presentation!

   The documentation isn't fully up-to-date yet. You can have a look at `sliphub.choum.net <https://sliphub.choum.net>`_ for some preliminary information.

**Slipshow is a tool specifically designed for technical presentations where traditional slides are not enough.**

In a slipshow presentation, the equivalent of a slide is called a *slip*. Each slip is like a slide, but with no bottom limit. That is, the content can be arbitrarily long! During the presentation, the camera will "scroll" down to reveal the hidden content, following a script given by the presenter!

Here are the goals of slipshow, in no specific orders:

- Lift restrictions from traditional slide-based presentation. In particular, make it closer to a blackboard presentation!
- Easy to write and readable syntax: markdown with few extensions. No manual placement like in powerpoint. No crazy syntax like in latex.
- Source of the presentation is plain text: much better for source control, sharing with people, using your favorite editor, readability, compatibility.
- Open the possibility for a dynamic presentation. Watching scientific popularization video demonstrates how well-chosen animations can make a difficult subject more understandable.

Slipshow compiles files written in an extension of markdown, to a standalone html file viewable offline in any web browser.

We advise you to start by reading the :ref:`tutorial`. You can also peek at the :ref:`examples`.

.. toctree::
   :maxdepth: 1
   :caption: Contents:

   quick-start
   tutorial
   syntax
   themes
   listAttributes
   faq
   examples

..
   Indices and tables
   ==================

   * :ref:`genindex`
   * :ref:`modindex`
   * :ref:`search`
