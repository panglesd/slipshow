=========================================
Custom scripts for ultimate extensibility
=========================================

Slipshow allows to execute a custom script at any step of a presentation.

.. slipshow-example::

   {#id}
   Hello World!

   {exec}
   ```slip-script
   document.querySelector("#id").style.background = "red"
   ```

This is great! It allows to include in a slipshow any Javascript you want, for instance for your animations, simulation, etc, in a breeze.

However, there is a catch. What happens when you "go back" to a step before the
execution of the script? How to undo all the side effects that happened, to go
back to the previous step? Try to go back in the example above: it does not undo
the side effect!

Slipshow needs a bit more information. It needs to be provided the "reverse" of
the execution of the script. And indeed, that is one way: just return the
function to undo the script, wrapped in an object.


.. slipshow-example::

   {#id}
   Hello World!

   {exec}
   ```slip-script
   document.querySelector("#id").style.background = "red";
   return {undo: () => {
     document.querySelector("#id").style.background = "";
   }}
   ```

That is great! However, it is not always easy to compute a script to undo the side effects. Consider for example if we change the background of multiple elements, and they all have different initial background.

.. slipshow-example::

   {.c style=background:purple}
   Hello World!

   {.c style=background:green}
   Salut les potos!

   {.c style=background:yellow}
   ¡Hola chicos y chicas!

   {exec}
   ```slip-script
   document.querySelectorAll(".c").forEach(e => e.style.background = "red");
   return {undo: () => {
     document.querySelectorAll(".c").forEach(e => e.style.background = "");
   }}
   ```

This is wrong: when we go back, we lost the original background of the elements.

For such cases Slipshow provides an API. For instance, ``slip.setStyle`` allows
to set the style of an element, while recording that the change need to be
inverted when the moment comes. When using it, not need to return an "undo"
function, it will be inferred by Slipshow through the API calls.

.. slipshow-example::

   {.c style=background:purple}
   Hello World!

   {.c style=background:green}
   Salut les potos!

   {.c style=background:yellow}
   ¡Hola chicos y chicas!

   {exec}
   ```slip-script
   document.querySelectorAll(".c").forEach(e =>
     slip.setStyle(e, "background", "red")
   );
   ```

And here we have it: An easy to write script that allows Slipshow to cancel its
side-effects! The API available via ``slip`` allows more than just setting
style, you can find the full API in :doc:`the reference <actions-api>`. And in
case you want to do something that is not in the API, you have an escape hatch!
The function ``slip.onUndo`` allows you to register your own undo function. For
instance:

.. slipshow-example::

   {#id1}
   Content 1.

   {exec}
   ```slip-script
   function setTextContent(e, txt) {
     let old = e.innerText;
     e.innerText = txt;
     slip.onUndo(() => {e.innerText = old})
   }

   let e1 = document.querySelector("#id1");

   setTextContent(e1, "Intermediate value");
   setTextContent(e1, "Changed my mind");
   ```


