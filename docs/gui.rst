========
GUI mode
========

Slipshow has a "GUI mode", allowing you to place some elements using the mouse
on the preview.

.. warning::

   The GUI mode is currently only available when previewing the presentation
   through an editor. Refer to `<editor-setup>`_.

Defining a GUI element
----------------------

By default, elements in Slipshow are placed automatically by the browser's
engine. They follow the "text flow", ofter from top to bottom. "GUI" elements
will be removed from the text flow, and their position will be determined by
mouse dragging in the preview.

In order to define an element as a "GUI" element, you only need to add the
``gui`` attribute to it.

.. code-block::

   Some paragraph.

   {gui}
   A GUI element.

   Another paragraph.

Note that the two non-GUI paragraphs will be next to each other: since the GUI
element is removed from the text flow, it does not take any space.

Entering GUI mode
-----------------

The GUI mode is the mode that allows you to select, move rescale and redimension
your GUI elements.

To enter it, click on the "GUI mode" button in the top left toolbar. You can
also use the shortcut, :kbd:`Shift+G`.

Selecting a GUI element
-----------------------

In order to place a GUI element, you need to select it first. You have two options:
- From the GUI mode, select the "Select" tool in the top-left toolbar, and click
  on the element you want to select.
- Or, from your editor, move the cursor on the ``gui`` attribute of the element
  you wish to select.

Moving a GUI element
--------------------

Once the element is selected, the current tool should be the "Move" tool
(otherwise, select this tool on the top-left toolbar).

Simply click and drag anywhere on the preview (it does not need to be on the
selected element).

Any move will be instantly saved in the editor, as a value for the ``gui``
attribute.

Rescaling a GUI element
-----------------------

Rescaling an element changes its rendered size: magnifying and shrinking it
globally.

Select an element, choose the Rescale tool from the top-left toolbar, and drag
anywhere on the preview to rescale the element. The changes is saved in the
value of the ``gui`` attribute.

Dimensioning a GUI element
--------------------------

Dimensioning an element changes its container size: the text does not change
size but reflows.

Select an element, choose the Dimension tool from the top-left toolbar, and drag
anywhere on the preview to dimension the element. The changes is saved in the
value of the ``gui`` attribute.

Anchors for GUI elements
------------------------

GUI elements are placed relative to where they would be if they were not GUI
elements. So in the example above, if the both paragraphs grow in size, only the
growth of the first one would affect the position of the GUI element.

Some care in where you anchor your GUI elements allows you to add content in
unrelated places of your presentation, without changing the position of your GUI
elements relative to their neighbour.
