.. _listAttributes:

Slipshow API
============


.. contents:: Table of contents
   :local:

----------------
      
      
Slip-specific tags
----------------------------------------------

We list here the custom tags that are specific to slipshow.

.. _slip-slipshow:

``slip-slipshow``
~~~~~~~~~~~~~~~~~
  The root of a slipshow.

.. _slip-slip:

``slip-slip``
~~~~~~~~~~~~~~~~~
  A slip.

.. _slip-title:

``slip-title``
~~~~~~~~~~~~~~~~~
  The title of a slip.

.. _slip-body:

``slip-body``
~~~~~~~~~~~~~~~~~
  The body of a slip.




Slip-specific classes
----------------------------------------------

We list here the class that can be given to elements that are specific to slipshow.

.. _unrevealed:

``unrevealed``
~~~~~~~~~~~~~~~~~
  Make an element invisible. Can be made visible with :ref:`mk-visible-at` or :ref:`chg-visib-at`.
  
.. _movable:

``movable``
~~~~~~~~~~~~~~~~~
  Make an element move smoothly when moved using the not yet implemented ``move-element-to``.
  
.. _emphasize:

``emphasize``
~~~~~~~~~~~~~~~~~
  Emphasize the element.

.. _no-flex:

``no-flex``
~~~~~~~~~~~~~~~~~
  If a slip has this class, the content will not be centered vertically. That is, even if there is only one line, it will appear in the top, and not in the middle.


----------------

  
``at`` attributes
----------------------------------------------

Here, we list the attributes that act at predefined steps of the presentation.

.. _mk-visible-at:

``mk-visible-at``
~~~~~~~~~~~~~~~~~
  If an element has attribute ``mk-visible-at="n"``, then it will be made visible at step :math:`n`. It only has an effect if the element is hidden, for instance by ``mk-hidden-at`` or the ``invisible`` class.
  
.. _mk-hidden-at:

``mk-hidden-at``
~~~~~~~~~~~~~~~~~
  If an element has attribute ``mk-hidden-at="n"``, then it will be hidden at step :math:`n`.
  
.. _mk-emphasize-at:

``mk-emphasize-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``mk-emphasize-at="n"``, then it will be given the ``emphasize`` class at step :math:`n`.

.. _mk-unemphasize-at:

``mk-unemphasize-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``mk-unemphasize-at="n"``, then it will be removed the ``emphasize`` class at step :math:`n`.

.. _emphasize-at:

``emphasize-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``emphasize-at="n0 n1 n2 ..."``, then it will be emphasized exactly at steps :math:`n_0`, :math:`n_1`, :math:`n_2`, ...

.. _chg-visib-at:

``chg-visib-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``chg-visib-at="n0 n1 n2 ..."``, then it will hidden at step 0, it will be made visible at positive steps :math:`n_i`, and it will be hidden at negative steps :math:`n_j`. For instance, ``chg-visib-at="2 -5 8"`` will first appear hidden, then visible at step 2, invisible at step 5 and visible again at step 8.

.. _up-at:

``up-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``up-at="n"``, then the window will move at step :math:`n` so that the element appear at the top of the screen.

.. _down-at:

``down-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``down-at="n"``, then the window will move at step :math:`n` so that the element appear at the bottom of the screen.

.. _center-at:

``center-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``center-at="n"``, then the window will move at step :math:`n` so that the element appear at the center of the screen.

.. _focus-at:

``focus-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``focus-at="n"``, then the window will move at step :math:`n` so that the element takes all the screen.

.. _unfocus-at:

``unfocus-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``unfocus-at="n"`` at step :math:`n`, and the window was focusing on an element, then the window will return to its original place.

.. _static-at:

``static-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``static-at="n0 n1 n2 ..."``, then it will be added to the text flow at positive steps :math:`n_i`, and removed from the text flow at steps :math:`n_j`. Note that this does not work by modifying the ``static`` css property, but rather by setting the css properties ``position: absolute`` and ``visibility: hidden``. This is done so that mathjax can compute the size of the elements that includes math, it cannot when an element is not static. 

.. _exec-at:

``exec-at``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has attribute ``exec-at="n"``, then its content will be executed at step :math:`n`. See :ref:`slip-scripting` for more information on the execution of a script.

----------------


``pause`` attributes
---------------------------

Here, we list all the attributes that are linked with the ``pause`` mechanism. At each step of the slipshow, the first pause attribute acts, and is removed. We describe what are the action of each pause attributes.

.. _pause:

``pause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  If an element has a ``pause`` attribute, all elements appearing after it will be hidden. A ``pause`` attribute, when acting, only disappear, revealing the content of the slip until the next pause attribute. A ``pause`` attribute can have a value: if an element has ``pause="n"``, then it will take 5 steps to disappear.

.. _step:

``step``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  A ``step`` attribute, when acting, only disappear. This does nothing but allows to make a stop in the pause flow.  A ``step`` attribute can have a value: if an element has ``step="n"``, then it will take 5 steps to disappear. This attribute is mostly useful in combinaison with the :ref:`at-unpause-attributes`.

.. _auto-enter:

``auto-enter``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When given focus, a slip with the ``auto-enter`` attribute will be entered.

.. _immediate-enter:

``immediate-enter``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  One step before being given focus, a slip with the ``immediate-enter`` attribute will be entered. This is needed so that slips are entered directly, and not after one action.


----------------
  
.. _at-unpause-attributes:

``at-unpause`` attributes
-----------------------------

When an element has focus from the pause mechanism, and its attribute is removed (for instance, after 5 focus if it has ``pause="5"``), we say that the element is unpaused. 

.. _up-at-unpause:

``up-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``up-at-unpause`` attribute is unpaused, the window will move so that the element appear at the top of the screen. If the attribute has a value, e.g. ``up-at-unpause="id"``, then the element with id ``id`` will be put at the top of the screen instead.
  
.. _down-at-unpause:

``down-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``down-at-unpause`` attribute is unpaused, the window will move so that the element appear at the bottom of the screen. If the attribute has a value, e.g. ``down-at-unpause="id"``, then the element with id ``id`` will be put at the bottom of the screen instead.

.. _center-at-unpause:

``center-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``center-at-unpause`` attribute is unpaused, the window will move so that the element appear at the center of the screen. If the attribute has a value, e.g. ``center-at-unpause="id"``, then the element with id ``id`` will be put at the center of the screen instead.

.. _focus-at-unpause:

``focus-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``focus-at-unpause`` attribute is unpaused, the window will move so that the element takes all the screen. If the attribute has a value, e.g. ``focus-at-unpause="id"``, then the element with id ``id`` will be the one taking all the screen instead.  

.. _unfocus-at-unpause:

``unfocus-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``focus-at-unpause`` attribute is unpaused, and the window was focusing on an element, the window will return to its original place.

.. _exec-at-unpause:

``exec-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``exec-at-unpause`` attribute is unpaused, the content of the element will be executed. If the attribute has a value, e.g. ``exec-at-unpause="id"``, then the element with id ``id`` will be executed instead. See :ref:`slip-scripting` for more information on the execution of a script.

.. _static-at-unpause:

``static-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``static-at-unpause`` attribute is unpaused, the element will be made "static" at unpause. If the attribute has a value, e.g. ``static-at-unpause="id1 id2 ..."``, then the element with thos ids will be made static at unpause. By "made static" we mean the css styling ``position:static; visibility:visible`` will be applied.

.. _unstatic-at-unpause:

``unstatic-at-unpause``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  When an element with the ``unstatic-at-unpause`` attribute is unpaused, the element will be made "unstatic" at unpause. If the attribute has a value, e.g. ``unstatic-at-unpause="id1 id2 ..."``, then the element with those ids will be made unstatic at unpause. By "made unstatic" we mean the css styling ``position:absolute; visibility:hidden`` will be applied.


----------------
  
.. _slip-scripting:

Slip scripting
---------------------------

A slip script can be executed either with :ref:`exec-at`, :ref:`exec-at-unpause`, :ref:`setAction`, or :ref:`setNthAction`. It consists of plain javascript, with an additional variable ``slip`` containing the slip inside which it is executed.

.. _query:

``slip.query``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _queryAll:

``slip.queryAll``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _slip.delay:

``slip.delay``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _reveal:

``slip.reveal``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _downTo:

``slip.downTo``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _centerTo:

``slip.centerTo``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.. _upTo:

``slip.upTo``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.. _focus:

``slip.focus``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _unfocus:

``slip.unfocus``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _setAction:

``slip.setAction``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _setNthAction:

``slip.setNthAction``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _getEngine:

``slip.getEngine``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _getRoot:

``engine.getRoot``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _start:

``engine.start``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _restart:

``engine.restart``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _getController:

``engine.getController``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _startSlipshow:

``Slipshow.startSlipshow``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _Slip:

``Slipshow.Slip``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _Engine:

``Slipshow.Engine``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
