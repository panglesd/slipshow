.. _tutorial:

Tutorial
========

Slip.js is a library for displaying slips. The easiest way is to include the library using a CDN, this is the option we choose to use in this tutorial for its simplicity. However, in this case you will not be able to display your slips without internet access. To use a local version, see :ref:`getting-started`.

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

.. note:: If you don't include the ``div`` with ``class=slip-body-container``, the slip will have no margin. It can be usefull if you want to display something "fullscreen".
  
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
	  <div class="block" title="A block">
	    Here is a block
	  </div>
	  <div class="definition" title="Theme">
	    The theme is the styling of a presentation. It includes the colors  given to the different blocks.
	  </div>
	  <div class="theorem" title="Meta Theorem">
	    This is a theorem.
	  </div>
	  <div class="example" title="A block">
	    For instance, this is an example.
	  </div>
	</div>
      </div>

      
Using the full power of slips
-----------------------------

Until now, we have only used the "classic" part of slideshow presentation. Slip allows some more things!

Moving the point of view
^^^^^^^^^^^^^^^^^^^^^^^^

Sometimes, you need to show things below the bottom of the slip. You can do this by using one of the attribute ``top-at``,  ``center-at``,  ``bottom-at``, which moves the screen to make the element be at the top (respectively center, bottom) of the screen.

For instance, copy paste this new slip and test the different attributes.

.. code-block:: html
		
      <div class="slip" immediate-enter>
        <div class="titre">Blocks</div>
        <div class="slip-body-container">
	  <div class="block" title="Lispum">
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	  </div>
	  <div down-at="1">
	    That was long!
	  </div>


Acting at unpause
^^^^^^^^^^^^^^^^^^^^^^^^

Until now, we have seen two mechanisms: the "pause" mechanism, which allows to make things appear one by one, and the "absolute" mechanism, where we specify the step number where things are emphasized or "moved to".

The "absolute" mechanism allows more control, however it is sometimes heavier to work with it. Indeed, slips can become quite long, and if you want to add one step at the beginning, you might have to change every ``emphasize-at`` and ``down-at`` values to increment them by one, by hand.

However, there is a way to couple the "pause" mechanism with other actions than pauses, using the ``*-at-unpause``, where ``*`` can be multiple things, for instance ``down-at-unpause``.

.. code-block:: html
		
      <div class="slip" immediate-enter>
        <div class="titre">Déclaration des droits de l'Homme et du Citoyen</div>
        <div class="slip-body-container">
	  <ol>
	    <li>Les hommes naissent et demeurent libres et égaux en droits. Les distinctions sociales ne peuvent être fondées que sur l'utilité commune.</li>
	    <li pause>Le but de toute association politique est la conservation des droits naturels et imprescriptibles de l'homme. Ces droits sont la liberté, la propriété, la sûreté, et la résistance à l'oppression.</li>
	    <li pause>Le principe de toute souveraineté réside essentiellement dans la nation. Nul corps, nul individu ne peut exercer d'autorité qui n'en émane expressément.</li>
	    <li pause>La liberté consiste à pouvoir faire tout ce qui ne nuit pas à autrui : ainsi, l'exercice des droits naturels de chaque homme n'a de bornes que celles qui assurent aux autres membres de la société la jouissance de ces mêmes droits. Ces bornes ne peuvent être déterminées que par la loi.</li>
	    <li pause>La loi n'a le droit de défendre que les actions nuisibles à la société. Tout ce qui n'est pas défendu par la loi ne peut être empêché, et nul ne peut être contraint à faire ce qu'elle n'ordonne pas.</li>
	    <li pause>La loi est l'expression de la volonté générale. Tous les citoyens ont droit de concourir personnellement, ou par leurs représentants, à sa formation. Elle doit être la même pour tous, soit qu'elle protège, soit qu'elle punisse. Tous les citoyens étant égaux à ses yeux sont également admissibles à toutes dignités, places et emplois publics, selon leur capacité, et sans autre distinction que celle de leurs vertus et de leurs talents.</li>
	    <li pause>Nul homme ne peut être accusé, arrêté ni détenu que dans les cas déterminés par la loi, et selon les formes qu'elle a prescrites. Ceux qui sollicitent, expédient, exécutent ou font exécuter des ordres arbitraires, doivent être punis ; mais tout citoyen appelé ou saisi en vertu de la loi doit obéir à l'instant : il se rend coupable par la résistance.</li>
	    <li pause>La loi ne doit établir que des peines strictement et évidemment nécessaires, et nul ne peut être puni qu'en vertu d'une loi établie et promulguée antérieurement au délit, et légalement appliquée.</li>
	    <li pause down-at-unpause>Tout homme étant présumé innocent jusqu'à ce qu'il ait été déclaré coupable, s'il est jugé indispensable de l'arrêter, toute rigueur qui ne serait pas nécessaire pour s'assurer de sa personne doit être sévèrement réprimée par la loi.</li>
	    <li pause down-at-unpause>Nul ne doit être inquiété pour ses opinions, même religieuses, pourvu que leur manifestation ne trouble pas l'ordre public établi par la loi.</li>
	    <li pause down-at-unpause>La libre communication des pensées et des opinions est un des droits les plus précieux de l'homme : tout citoyen peut donc parler, écrire, imprimer librement, sauf à répondre de l'abus de cette liberté dans les cas déterminés par la loi.</li>
	    <li pause down-at-unpause>La garantie des droits de l'homme et du citoyen nécessite une force publique : cette force est donc instituée pour l'avantage de tous, et non pour l'utilité particulière de ceux auxquels elle est confiée.</li>
	    <li pause down-at-unpause>Pour l'entretien de la force publique, et pour les dépenses d'administration, une contribution commune est indispensable : elle doit être également répartie entre tous les citoyens, en raison de leurs facultés.</li>
	    <li pause down-at-unpause>Tous les citoyens ont le droit de constater, par eux-mêmes ou par leurs représentants, la nécessité de la contribution publique, de la consentir librement, d'en suivre l'emploi, et d'en déterminer la quotité, l'assiette, le recouvrement et la durée.</li>
	    <li pause down-at-unpause>La société a le droit de demander compte à tout agent public de son administration.</li>
	    <li pause down-at-unpause>Toute société dans laquelle la garantie des droits n'est pas assurée, ni la séparation des pouvoirs déterminée, n'a point de Constitution.</li>
	    <li pause down-at-unpause>La propriété étant un droit inviolable et sacré, nul ne peut en être privé, si ce n'est lorsque la nécessité publique, légalement constatée, l'exige évidemment, et sous la condition d'une juste et préalable indemnité.</li>
	  </ol>
	</div>
      </div>

.. tip:: You can make the ``*-at-unpause`` act on another element by specifying its ``id`` as value of the attribute.

.. todo:: The attribute ``emphasize-at-unpause`` is not yet implemented but it will be very soon!


Subslips of slips
^^^^^^^^^^^^^^^^^^^^^^^^

In slips, a presentation is not anymore linear, but has rather the shape of a tree, just like any text, with section, subsection. So a slip can easily contain slips inside itself !

Consider the following example, that you can add as a new slip:

.. code-block:: html

      <div class="slip" immediate-enter>
          <div class="titre">A review of the numbers</div>
          <div class="slip-body-container">
	      <div>First, we consider the positive numbers</div>
	      <div style="display: flex; justify-content: space-around;">
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The integer</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>1 is an integer,</li>
			      <li pause>2 is an integer,</li>
			      <li pause>100 is an integer.</li>
			  </ul>
		      </div>
		  </div>
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The rationnals</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>1/2 is a rational,</li>
			      <li pause>2/3 is a rational,</li>
			      <li pause>567/87 is a rational.</li>
			  </ul>
		      </div>
		  </div>
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The reals</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>π is a real,</li>
			      <li pause>e is a real,</li>
			      <li pause>d is a real.</li>
			  </ul>
		      </div>
		  </div>
	      </div>
	      <div pause>Then, the negative one</div>
	      <div style="display: flex; justify-content: space-around;">
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The integer</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>-1 is an integer,</li>
			      <li pause>-2 is an integer,</li>
			      <li pause>-100 is an integer.</li>
			  </ul>
		      </div>
		  </div>
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The rationnals</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>-1/2 is a rational,</li>
			      <li pause>-2/3 is a rational,</li>
			      <li pause>-567/87 is a rational.</li>
			  </ul>
		      </div>
		  </div>
		  <div delay="1" scale="0.25" class="slip" auto-enter>
		      <div class="titre">The reals</div>
		      <div class="slip-body-container">
			  <ul>
			      <li>-π is a real,</li>
			      <li pause>-e is a real,</li>
			      <li pause>-d is a real.</li>
			  </ul>
		      </div>
		  </div>
	      </div>
	  </div>
      </div>


In this example, there are several new things:

* The flexbox ``div`` container is just plain css to make the subslips well aligned,
* The ``scale`` attribute scales the slip. It is better than a css transform as not only the rendering is smaller, but also the size.
* The ``delay`` attribute make the camera move slowly to enter the slip.

.. note:: The difference between ``immediate-enter`` and ``auto-enter`` is that a slip with ``immediate-enter`` will be entered before the pause, while ``auto-enter`` will be entered after one stop.

.. note:: The transition back to the parent slip is not very good at this point. This is because the parent slip has ``delay="0"`` by default. We wanted this as we do not want to enter this slip "smoothly" the first time. We will see in Javascripting your presentation how to modify this.

The table of content
^^^^^^^^^^^^^^^^^^^^^^^^

When you press ``t`` during your presentation. Magic!
	  
Javascripting your presentation
--------------------------------

Let us now focus on the second part of the file: the Javascript. Although it is not necessary to modify it, in some special cases you might need to specify it.

.. code-block:: html

       <script>
       	 let engine = new Engine(document.querySelector("#rootSlip"));
	 let controller = new Controller(engine);
	 // customize the presentation here with JS 
	 engine.start();
       </script>

The object ``engine`` what the object that will tak care of the presentation: how to handle 

Themes
-----------------------------
