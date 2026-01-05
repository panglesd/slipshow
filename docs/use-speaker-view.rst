====================
Use the speaker view
====================

Anatomy of a speaker view
=========================

The speaker view contains several elements:

- A mirror of the presentation.
- A timer and clock.
- Your notes.

You can open it by pressing :key:`s` after opening the presentation.

Adding notes
============

You can add notes with the ``speaker-notes`` action.

.. code-block::

   {speaker-note}
   My note

   {speaker-note}
   > Another node
   >
   > With multiple paragraphs

A speaker note is not displayed in the presentation. When the ``speaker-note``
action is executed, the note replaces the current note in the speaker view.

You can also have the :ref:`speaker note and its execution be split <anatomy>` by using an identifier:

.. code-block::

   {#my-note}
   It's more readable for this speaker note to be here

   Lots of content and actions.

   {speaker-note=my-note}

Finally, it is possible to have the notes appear at the same time as any other action:

.. code-block::

   {#title}
   # Hello

   {speaker-note up=title}
   My note

The speaker view and complex workflow
=====================================

Slipshow tries to synchronize the two presentation view. For instance, if you
press :key:`Right arrow` in one, it changes step in both. Similarly for drawing.

However, there are things that cannot really be synchronized. For instance, if
you write text in an input box. In this case, I encourage you to mirror your
*screen* and not the presentation. Slipshow will `soon support
<https://github.com/panglesd/slipshow/pull/188>`_ that out of the box.
