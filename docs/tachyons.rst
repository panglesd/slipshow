========
Tachyons
========

`Tachyons <https://tachyons.io/>`_ is a CSS framwork. It allows to style
elements by assigning them classes. For instance, to give a blue text color on a
red background:

.. code-block::

   ---
   tachyons: true
   ---

   {.blue .bg-red}
   Hello!

As seen in the example above, the inclusion of tachyons is not automatic, you
need to add it to the frontmatter.

You can find all classes and the corresponding CSS rule in the `tachyons doc
<https://tachyons.io/docs/>`_. Note however that no "media query" rules are
included, nor the ``font-family`` ones (as fonts need to be embedded to have a
truly standalone HTML file).
