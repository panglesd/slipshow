.. _tutorial:

Tutorial
========

Slip.js is a library for displaying slips. The easiest way is to include the library using a CDN, this is the option we choose to use in this tutorial for its simplicity. However, in this case you will not be able to display your slips without internet access. To use a local version with npm, see :ref:`getting-started`.

..
   You can also install slip-js it using npm.

A minimal file, using a CDN
---------------------------

A presentation is just a html file, together with some javascript and css. For simple presentation, you will only need to write some html.

The minimal example of a slip presentation still need to include both the css and the javascript. Either you have the files locally, or you include them from a CDN, a "Content Delivery Network". In the second option, a minimal file looks like the following:

.. code-block:: html

   <!doctype html>
   <html>
     <head>
       <!-- Add css and theme -->
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/css/slip.css">
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/css/theorem.css">
     </head>
     <body>

     <!-- This is the presentation -->
       <div class="root" id="rootSlip">
         <!-- Add the slips here -->
       </div>

     <!-- Include the library -->
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/slip-lib.cdn.min.js"></script>
       <!-- Start the presentation () -->
       <script>
       	 let engine = new Engine(document.querySelector("#rootSlip"));
	 let controller = new Controller(engine);
	 // customize the presentation here with JS 
	 engine.start();
       </script>
     </body>
   </html>

..
   or in pug:

   .. code-block:: pug

   html
     head
       script(src="https://panglesd.github.io/slip-js/src/slip-lib.js")
     body
       #rootSlip.root


Create a file named ``myPresentation.html`` and copy-paste the minimal example. Now open it with a browser. What do you see? Nothing!

Writing standard slips
-----------------------
In this section, we learn how to add slips.

Adding a plain slip
^^^^^^^^^^^^^^^^^^^
Modify the file ``myPresentation.html`` to turn:

.. code-block:: html

     <!-- This is the presentation -->
       <div class="root" id="rootSlip">
         <!-- Add the slips here -->
       </div>

into

.. code-block:: html

     <!-- This is the presentation -->
       <div class="root" id="rootSlip">
         <div class="slip" immediate-enter>
           <div class="titre">My first slip</div>
           <div class="slip-body-container">
	     <div>Here is the content of my first slip:</div>
	     <ul>
	       <li>A title</li>
	       <li>Some text</li>
	       <li>An itemized list</li>
	     </ul>
	   </div>
	 </div>
       </div>

Now save the file and reload the page. Suddenly there is something in the screen! Let us describe what each of these things mean.

* ``<div class="slip">...</div>`` defines the boundary of the new slip.
* the attribute ``immediate-enter`` ensures that the slips will be entered in order.
* ``<div class="titre">...</div>`` defines the title of the slip. Notice the french orientation! (TODO: remove the french orientation)
* ``<div class="slip-body-container">...</div>`` defines the body of the slip. It includes margin, padding,...

The rest is pure html. For latex users, just translate your ``\begin{itemize}`` and ``\end{itemize}`` respectively into ``<ul>`` and ``</ul>``, and you ``\item`` into ``<li>...</li>``.

Making pauses
^^^^^^^^^^^^^

Add another slip with the following content:

.. code-block:: html

         <div class="slip" immediate-enter>
           <div class="titre">Question</div>
           <div class="slip-body-container">
	     <div>What do you think are my three favourite colors?</div>
	     <ul>
	       <li>Green</li>
	       <li>Orange</li>
	       <li>Apple</li>
	     </ul>
	     <div>And you?</div>
	   </div>
	 </div>

Reload the page and push the right arrow. You see the new slip appearing. Suppose that we don't want to reveal directly the results, but we want to show them one by one. This is done with the pause mechanism. At each push of the right arrow, everything after a ``pause`` attribute is revealed, until the next ``pause``. Transform the list into this:

.. code-block:: html
		
	     <ul>
	       <li pause>Green</li>
	       <li pause>Orange</li>
	       <li pause>Apple</li>
	     </ul>

Reload and see what it does! It does what was expected.

.. warning:: You should never let some plain text be in a slip, otherwise the "pause" mechanism won't work for it! This is because css styling cannot be made to text node. For instance, try to remove the "And you?" outside of a div, it won't be affected by the pause.

Emphasizing
^^^^^^^^^^^^^

It is common in presentation to emphasize or highlight some words. The following slip shows how it works in slip, add it to your file.

.. code-block:: html

         <div class="slip" immediate-enter>
           <div class="titre">Emphasizing</div>
           <div class="slip-body-container">
	     <div>I have <span emphasize-at="1 4">nothing to say</span> but my <span emphasize-at="2 4">words</span> are <span emphasize-at="3 4">important</span>!</div>
	   </div>
	 </div>

This is pretty self-explanatory! When the attribute emphasize-at is setted to a list of numbers separated by spaces, the content will be emphasized exactly at these steps! There are several other way to emphasize depending on the need, such as ``mk-emphasize-at``, see the doc.

Stating theorems
^^^^^^^^^^^^^^^^^
To state a theorem, juste create a ``div`` with the right class, that is either ``block``, ``definition``, ``theorem`` or ``example``. You can also give a title to any of those with the attribute ``title``.

For instance, add the following slip to your presentation and reload it.

.. code-block:: html
		
      <div class="slip" immediate-enter>
        <div class="titre">Blocks</div>
        <div class="slip-body-container">
	  <div class="block" title="A block">Here is a block</div>
	  <div class="definition" title="Theme">The theme is the styling of a presentation. It includes the colors  given to the different blocks.</div>
	  <div class="theorem" title="Meta Theorem">This is a theorem.</div>
	  <div class="example" title="A block">For instance, this is an example.</div>
	</div>
      </div>

      
Using the full power of slips
-----------------------------


Moving the point of view
^^^^^^^^^^^^^^^^^^^^^^^^

Acting at unpause
^^^^^^^^^^^^^^^^^^^^^^^^
