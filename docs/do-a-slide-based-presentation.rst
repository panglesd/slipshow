=============================
Do a slide-based presentation
=============================


Suppose you want to do a presentation that consists uniquely of slides. In this
case, you can add ``children:slide children:enter=~duration:0`` as
toplevel-attributes in the frontmatter.

Once you have added this in the frontmatter, separate your slides with ``---``,
just like you would in a revealJS presentation. The rest of the syntax
(``{pause}``, etc) and feature stay unchanged.

.. slipshow-example::

   ---
   toplevel-attributes: children:slide children:enter=~duration:0
   ---

   # Slide 1

   Slips are obviously better

   ---

   # Slide 2

   I'm joking of course!

   {pause}
   Unless I'm not?
