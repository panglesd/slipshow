============================
Revealing figures bit by bit
============================

To reveal a figure bit by bit, you have two main options:

- The first is to create your figure in SVG. This way, you can add identifiers
  and classes to the relevant parts of the figure which you can then target from Slipshow.
- The other is to have multiple versions of the figure as images, and use a
  carousel to switch between them.

Using an SVG figure
===================

Similar to Slipshow documents, an SVG image can contain classes and ids.

This allows displaying the image bit by bit, just as we would do that for text
in a Slipshow:

.. code-block:: md

   <!-- file.svg contains an svg with the my-square identifier -->

   ![](file.svg)

   {reveal=my-square}

All that remains is to know how to add identifiers and classes to the SVG elements.

In Inkscape
-----------

To add an id, select the element you want to add an identifier (it can be a
group).

Then, go to the ``Object Properties`` view in the ``Object`` menu.

Under ``Properties``, you have the opportunity to change the ``ID`` for the
selected object.

In order to add a class, select the ``CSS and selectors`` under the ``Object``
menu. Then, click on the bottom ``+`` named "Add a new CSS selector". Choose
``.class-name``, then replace the name with your own, retaining the leading ``.``.

The selected object is added the class. You can see the list of elements with
the class, and add some with the ``+`` button next to the class name.

By hand
-------

If you open an SVG image with a text editor, it looks like this:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg viewBox="0 0 10 10">
      <rect style="fill: red" width="6" height="6" x="2" y="2" />
      <rect style="fill: blue" width="2" height="2" x="8" y="8" />
    </svg>

You can add classes and IDs by editing the XML directly. For instance, to add an identifier nd a class to the red square:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg viewBox="0 0 10 10">
      <rect id="my-square" class="unrevealed" style="fill: red" width="6" height="6" x="2" y="2" />
      <rect style="fill: blue" width="2" height="2" x="8" y="8" />
    </svg>

Using a carousel
================

The other option is to create a separate image for each version of the figure you want to show, and use a
carousel to switch between them. The images need to have the same dimensions.

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
