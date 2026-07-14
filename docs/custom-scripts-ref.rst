==============
Custom scripts
==============

Use a ``slip-script`` code block to add a script, and ``exec`` to execute it.

.. code-block:: markdown

   {exec}
   ```slip-script
   // JavaScript code here
   ```

If a script has a "permanent" side-effect, it has to provide a way for Slipshow
to revert it. There are two ways to do that. One is to use a specific API for side
effects, which is the easiest and will accommodate most scripts. The other
is more general but slightly more work.

The ``slip`` API
================

The ``slip`` API allows execution of various actions:

``slip.up(element, duration, margin)``

   provides programmatic access to the ``up`` action.

``slip.center(element, duration, margin)``

   provides programmatic access to the ``center`` action.

``slip.down(element, duration, margin)``

   provides programmatic access to the ``down`` action.

``slip.focus(elementList, duration, margin)``

   provides programmatic access to the ``focus`` action.

``slip.unfocus()``

   provides programmatic access to the ``unfocus`` action.

``slip.static(elementList)``

   provides programmatic access to the ``static`` action.

``slip.unstatic(elementList)``

   provides programmatic access to the ``unstatic`` action.

``slip.reveal(elementList)``

   provides programmatic access to the ``reveal`` action.

``slip.unreveal(elementList)``

   provides programmatic access to the ``unreveal`` action.

``slip.emph(elementList)``

   provides programmatic access to the ``emph`` (emphasise) action.

``slip.unemph(elementList)``

   provides programmatic access to the ``unemph`` (unemphasise) action.

``slip.playMedia(elementList)``

   provides programmatic access to the ``play-media`` action.

``slip.draw(elementList)``

   provides programmatic access to the ``draw`` action.

``slip.changePage(element, page)``

   provides programmatic access to the ``change-page`` action, where ``page`` can
   be an absolute or relative number.

``slip.setStyle(element, style, value)``

   sets the ``style`` of ``element`` to ``value``.

``slip.setClass(element, className, boolean)``

   adds or removes (depending on ``boolean``) the class ``className`` of ``element``.

``slip.setProp(object, propertyName, value)``

   sets the property ``propertyName`` of ``object`` to ``value``.

``slip.onUndo(callback)``

   has no visible side-effect, but registers ``callback()`` to be run when going
   backward.

Providing your own ``undo`` functions
=====================================

When the API above is not enough, Slipshow provides a way to define your own
``undo`` functions. They need to be generated when the script runs, and they
will be called when inverting the step.

If you use the ``slip`` API, and want to fill a small gap in it, you can use
``slip.onUndo``, as defined above.  You can also override any side-effect
registered by the ``slip`` API by returning an undo function:

.. code-block:: markdown

   {exec}
   ```slip-script
   let elem = document.querySelector("#id")
   let old_value = elem.style.opacity;
   elem.style.opacity = "1";
   return {undo : () => { elem.style.opacity = old_value }}
   ```
