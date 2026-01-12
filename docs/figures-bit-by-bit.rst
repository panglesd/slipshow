=========================
Reveal figures bit by bit
=========================

To reveal a figure bit by bit, you have mostly two options:

- The first one is to have your figure in SVG. This way, you can add identifiers
  and classes to the relevant parts of the figure.
- The other one is to have multiple version of the figure as images, and use a
  carousel.

Using an SVG figure
===================

Similarly to slipshow document, an SVG image allow to add classes and ids.

This allows to display the image bit by bit just like we would do that for text
in a slipshow:

.. code-block:: md

   <!-- file.svg contains an svg with the my-square identifier -->

   ![](file.svg)

   {reveal=my-square}

It only remains to know how to add identifiers and classes.

In Inkscape
-----------

To add an id, select the element you want to add an identifier (it can be a
group).

Then, go to the ``Object Properties`` view, accessible among other options under
the ``Object`` menu.

Under ``Properties``, you have the opportunity to change the ``ID`` for the
selected object.

In order to add a class, select the ``CSS and selectors`` under the ``Object``
menu. Then, click on the bottom ``+`` named "Add a new CSS selector". Choose
``.class-name`` where you replace the name with your own, keeping the ``.``.

The selected object is added the class. You can see the list of elements with
the class, and add some with the ``+`` button next to the class name.

By hand
-------

If you open an SVG image with a text editor, it looks like this:

.. code-block:: svg

    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg viewBox="0 0 10 10">
      <rect style="fill: red" width="6" height="6" x="2" y="2" />
      <rect style="fill: blue" width="2" height="2" x="8" y="8" />
    </svg>

This allows you to add classes and IDs:

.. code-block:: svg

    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg viewBox="0 0 10 10">
      <rect id="my-square" class="unrevealed" style="fill: red" width="6" height="6" x="2" y="2" />
      <rect style="fill: blue" width="2" height="2" x="8" y="8" />
    </svg>

Using a carousel
================

The other options is to have one image file per version of the figure, and use a
carousel. The images need to be of the same dimension.

.. code-block::

   {carousel change-page=~n:all}
   > ![](figure-1.jpg)
   >
   > ![](figure-2.jpg)
   >
   > ![](figure-3.jpg)
   >
   > ![](figure-4.jpg)
   >
   > ![](figure-5.jpg)
