==============
Custom scripts
==============

Use a slipscript code block to add a script, and ``exec`` to execute it.

.. code-block:: markdown

   {exec}
   ```slip-script
   // JS script here
   ```

If a script has a "permanent" side-effect, it has to provide a way for slipshow
to revert it. There are two ways for that. One is to use a specific API for side
effects, which is the easiest and will accomodate most of the scripts. The other
one is more general but slightly more work.

The ``slip`` API
================

The ``slip`` API allows to do side effect, while :

``slip.up(element, duration, margin)``

   provides programatic access to the ``up`` action.

``slip.center(element, duration, margin)``

   provides programatic access to the ``center`` action.

``slip.down(element, duration, margin)``

   provides programatic access to the ``down`` action.

``slip.focus(elementList, duration, margin)``

   provides programatic access to the ``focus`` action.

``slip.unfocus()``

   provides programatic access to the ``unfocus`` action.

``slip.static(elementList)``

   provides programatic access to the ``static`` action.

``slip.unstatic(elementList)``

   provides programatic access to the ``unstatic`` action.

``slip.reveal(elementList)``

   provides programatic access to the ``reveal`` action.

``slip.unreveal(elementList)``

   provides programatic access to the ``unreveal`` action.

``slip.emph(elementList)``

   provides programatic access to the ``emph`` action.

``slip.unemph(elementList)``

   provides programatic access to the ``unemph`` action.

``slip.playMedia(elementList)``

   provides programatic access to the ``play-media`` action.

``slip.draw(elementList)``

   provides programatic access to the ``draw`` action.

``slip.changePage(element, page)``

   provides programatic access to the ``change-page`` action, where ``page`` can
   be an absolute or relative number.

``slip.setStyle(element, style, value)``

   allows to set the ``style`` of ``element`` to ``value``.

``slip.setClass(element, className, boolean)``

   allows to add or remove (depending on ``boolean``) the class ``className`` of ``element``.

``slip.setProp(object, propertyName, value)``

   allows to set the property ``propertyName`` of ``object`` to ``value``.

``slip.onUndo(callback)``

   does no side-effect, but register ``callback()`` to be run when going
   backward.

Providing your own ``undo`` functions
=====================================

When the API above is not enough, Slipshow provides a way to define your own
``undo`` functions. They need to be generated when the script runs, and they
will be called when inverting the step.

If you use the ``slip`` API, and want to fill a small gap in it, you can use
``slip.onUndo`` defined just above.  You can also override any side-effect
registered by the ``slip`` API by returning an undo function:

.. code-block:: markdown

   {exec}
   ```slip-script
   let elem = document.querySelector("#id")
   let old_value = elem.style.opacity;
   elem.style.opacity = "1";
   return {undo : () => { elem.style.opacity = old_value }}
   ```
