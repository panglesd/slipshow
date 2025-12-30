=======
Actions
=======

An action consists of a name, a set of possible arguments, and an effect. In this page, we describe all possible actions.

Inserting an action in the presentation is done by adding an attribute with the name of the action.

.. code-block::

   Some content.

   {center}

   Some other content.

The effect might be different when the attribute is attached to an element.

.. code-block::

   Some content.

   {center}
   Some other content.

Arguments can be added to an action. In this case, the attribute is a key-value attribute, the key being the name of the action, and the value containing the arguments.

.. code-block::

   {#one}
   Some content.

   {center=one}

   Some other content.

An action can have two kind of arguments: named arguments, and positional ones. Named argument are of the form ``~argument-name:value`` and positional are given as-is. The list of arguments is space-separated.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one"}

   Some other content.

It is possible to have multiple actions in a single attribute. They will be executed at the same step.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one" reveal="two three"}

   {#two .unrevealed}
   Some other content.

   {#three .unrevealed}
   Some more content.

.. contents:: Actions table of content
   :local:

Pause attributes
----------------

``pause``
  The pause attribute tells the slipshow engine that there is going to be a pause at this element. This element and every element after (but inside the "pause block") that in the document will be hidden.

``pause-block``
  The ``pause-block`` attribute tells the slipshow engine that pauses inside it should not hide content outside of it.

  Example:

  .. code-block:: markdown

     A

     {pause-block}
     > B
     >
     > {pause}
     >
     > C
     >
     > {pause}
     >
     > D

     E

  will initially display A, B and E, then going a step further will additionally display C, and another step will display D.

``step``
  Introduces a no-op step in the slip it's in. Useful to exit entered slips.

Moving the window
-----------------

``down``
  Moves the screen vertically until the element is at the bottom of the screen.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``up``
  Moves the screen vertically until the element is at the top of the screen.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``center``
  Moves the screen vertically until the element is centered.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``scroll``
  Moves the screen vertically until the element is entirely visible on screen, if possible.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``focus``
  Focus on the element by zooming on it. Possible to specify multiple ids.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``unfocus``
  Unfocus by going back to the last position before a focus.

Changing visibility
-------------------

``static``
  Make the element ``static``. By "static" we mean the css styling ``position:static; visibility:visible`` will be applied. Possible to specify multiple ids.

``unstatic``
  Make the element ``unstatic``. By "unstatic" we mean the css styling ``position:absolute; visibility:hidden`` will be applied. Possible to specify multiple ids.

``reveal``
  Reveal the element. By "revealing" we mean the css styling ``opacity:1`` will be applied.  Possible to specify multiple ids.

``unreveal``
  Hide the element. By "unrevealing" we mean the css styling ``opacity:0`` will be applied.  Possible to specify multiple ids.

Drawing actions
---------------

``draw``
  Replay the drawing. Possible to specify multiple ids. See :ref:`Record and replay drawings`.

``clear``
  Clear the drawing. Possible to specify multiple ids.

Carousels
---------

``change-page``
  Changes the current page of a carousel or pdf. Takes as input the id of the carousel/pdf.

  Also takes a ``~n:"<pages>"`` argument, which allows to specify the list of pages changes to do, by absolute number (e.g. ``4``), relative number (e.g. ``+1``, ``-2``), range (``3-10`` or ``5-3``), or ``all`` which displays one by one the page until completion. Default for ``~n`` is ``+1``.

  For instance, ``{change-page='~n:"2-4 6-4 7 -1 +2 all"'}`` will change pages to ``2``, ``3``, ``4``, ``6``, ``5``, ``4``, ``7``, ``6``, ``8`` and then all further pages that the pdf/carousel contains. It will always initially start with page 1.

Speaker notes
-------------

``speaker-note``
  Hides the targeted element (either with given ID, or self). When the action is executed, send the targeted element to the "Notes" section of the speaker notes (that you can open with ``s``).

Medias
------

``play-media``
  Play the media (audio or video). The associated element/target id(s) need to be a video element: a ``![](path)`` where path is recognized as a video or audio. Possible to specify multiple ids.

  Pay attention that browsers will prevent the playing if they consider that the user has not "interacted" with the page yet, in an effort to forbid spam "autoplay" of medias. Interact with the page (e.g. by clicking anywhere on it) to make sure it'll work.

Custom script
-------------

``exec``
  Execute the slipscript. Possible to specify multiple ids.
