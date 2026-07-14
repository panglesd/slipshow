=========================================
Custom scripts for ultimate extensibility
=========================================

Slipshow can execute a custom script (written in JavaScript) at any step of a presentation.

.. slipshow-example::

   {#id}
   Hello World!

   {exec}
   ```slip-script
   document.querySelector("#id").style.background = "red"
   ```

This is great! Include any JavaScript you want in a Slipshow, for instance for your animations, simulation, etc.

However, there is a catch. What happens when you "go back" to a step before the
execution of the script? How can you undo all the side effects that happened, to go
back to the previous step? Try to go back in the example above: it does not undo
the scripted effect!

Slipshow needs a bit more information. It needs to be provided with the "reverse" of
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

That's a start, but it is not always easy to write a script to undo the changes. Consider for example if we change the background of multiple elements, and they all have different initial backgrounds.

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

This is wrong: when we go back, we have lost the original element backgrounds.

Slipshow provides an API for such cases. For instance, ``slip.setStyle`` allows
setting the style of an element, while recording the changes needed to
invert them when the moment comes. When using this approach, it's not necessary to return an "undo"
function; it will be inferred by Slipshow through the API calls.

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

That's all there is to it! An easy to write script that allows Slipshow to undo its changes!
The API available via ``slip`` allows more than just setting
styles. You can find the full API in :doc:`the reference <actions-api>`.
If you want to do something that is not in the API, you have an escape hatch!
The function ``slip.onUndo`` allows you to register your own ``undo`` function, for
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
