=======
Actions
=======

An action consists of a name, a set of possible arguments, and an effect. This page describes all possible actions.

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

An action can have two kinds of arguments: named arguments, and positional ones. Named arguments are of the form ``~argument-name:value`` and positional arguments consist of only their value, not their names. The list of arguments is space-separated.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one"}

   Some other content.

It is possible to combine multiple actions in a single attribute, and they will be executed in the same step.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one" reveal="two three"}

   {#two .unrevealed}
   Some other content.

   {#three .unrevealed}
   Some more content.

Actions are executed in "reading order", from top left to bottom right. The
presenter needs to press the "next" key to trigger the next action.

.. code-block::

   {#one}
   Some content.

   {center="~duration:2 ~margin:10 one" reveal="two three"}
   The action above is executed first.

   {#two .unrevealed unreveal="three"}
   The action above is executed second.

   {#three .unrevealed}
   Some more content.

When the ``auto-continue`` attribute is included in the attribute set, the next
action is executed without requiring the user to press the "next" key.

.. code-block::

   {reveal="two" auto-continue}
   The action above is executed first.

   {#two .unrevealed center}
   The action above is executed directly after the first one.

.. contents:: Actions table of content
   :local:

Pause attributes
----------------

``pause``

  The pause attribute tells the Slipshow engine to pause the text rendering
  here. This element, and every element after it (but inside the "pause block")
  in the document, will be hidden.

  When a ``pause`` action is executed, the initially hidden text is displayed.

``pause-block``
  The ``pause-block`` attribute tells the Slipshow engine that pauses inside it should not hide content outside of it.

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

  will initially display ``A``, ``B`` and ``E``, then going a step further will additionally display ``C``, and another step will display ``D``.

``step``
  Introduces a no-op step in the slip it's in. Takes an optional ``~duration:FLOAT`` argument, whose default value is ``0``, and which defines the time spent before the action is completed. Useful to exit entered slips, and in conjunction with ``auto-continue``.

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
  Focus on the element by zooming on it. It's possible to specify multiple ids.

  Accepts ``~duration:FLOAT`` and ``margin:INT``.

``unfocus``
  Unfocus by going back to the last position before a focus.

Changing visibility
-------------------

``static``
  Make the element ``static``. By "static" we mean the css styling ``position:static; visibility:visible`` will be applied. It's possible to specify multiple ids.

``unstatic``
  Make the element ``unstatic``. By "unstatic" we mean the css styling ``position:absolute; visibility:hidden`` will be applied. It's possible to specify multiple ids.

``reveal``
  Reveal the element. By "revealing" we mean the css styling ``opacity:1`` will be applied. It's possible to specify multiple ids.

``unreveal``
  Hide the element. By "unrevealing" we mean the css styling ``opacity:0`` will be applied. It's possible to specify multiple ids.

Drawing actions
---------------

``draw``
  Replay the drawing. It's possible to specify multiple ids. See the how-to :ref:`record-and-replay:Record and replay drawings` and the tutorial :doc:`record-tutorial`.

``clear``
  Clear the drawing. It's possible to specify multiple ids.

Carousels
---------

``change-page``
  Changes the current page of a carousel or PDF. Takes the id of the carousel/PDF as input.

  It can also takes a ``~n:"<pages>"`` argument, which allows specifying a list of page changes to do, by absolute number (e.g. ``4``), relative number (e.g. ``+1``, ``-2``), range (``3-10`` or ``5-3``), or ``all`` which displays the pages one-by-one until completion. Default for ``~n`` is ``+1``.

  For instance, ``{change-page='~n:"2-4 6-4 7 -1 +2 all"'}`` will change pages to ``2``, ``3``, ``4``, ``6``, ``5``, ``4``, ``7``, ``6``, ``8`` and then all further pages that the carousel/PDF contains. It will always initially start with page 1.

Speaker notes
-------------

``speaker-note``
  Hides the targeted element (either with given ID, or self). When the action is executed, sends the targeted element to the "Notes" section of the speaker notes (that you can open with :kbd:`s`).

Media playback
--------------

``play-media``
  Play the media (audio or video). The associated element/target id(s) need to be a video element: a ``![](path)`` where the path is recognized as a video or audio file. It's possible to specify multiple ids.

  Be aware that browsers may prevent playback if they consider that the user has not "interacted" with the page yet, in an effort to forbid spam "autoplay" of media. Interact with the page (e.g. by clicking anywhere on it) to make sure it'll work.

Custom script
-------------

``exec``
  Execute the slipscript. It's possible to specify multiple ids.
