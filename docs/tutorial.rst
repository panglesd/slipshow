.. _tutorial:

Tutorial
========

Slipshow.js is a library for displaying slips. A presentation is just an ``html`` file. You do not need much knowledge on either ``html`` nor ``css`` and ``javascript`` to create slip presentations, but it allows any customization of your slips.

In this tutorial, you will create your first slip presentation. It is entirely self-contained but you should take a look at :ref:`getting-started` to know the different ways of creating a minimal file and starting a project, in particular if you want to write or show your presentation locally, without internet access. The first part is about the creation of simple presentation, following the usual concept of slides. The second part explains more advanced concepts on what makes slips different from other slideshow frameworks.

.. contents:: Outline of the tutorial
   :local:
   
..
   Writing slips should not differ too much from writing beamer presentation, when not using any of the advanced functionalities: there an delimiters for . The syntax is different, and there are 
..
   The easiest way is to include the library using a CDN, this is the option we choose to use in this tutorial for its simplicity. However, in this case you will not be able to display your slips without internet access. To use a local version, see :ref:`getting-started`.

..
   You can also install slip-js it using npm.

A minimal file
---------------------------

A presentation is just an ``html`` file. There are several ways to start a project and get a minimal file, described in :ref:`getting-started`. For self-coontainedness of the tutorial, we suppose you followed the "CDN" version, as it only requires you to copy the following text into a file, called for instance ``myPresentation.html``.

..
   The minimal example of a slip presentation still need to include both the css and the javascript. Either you have the files locally, or you include them from a CDN, a "Content Delivery Network". In the second option, a minimal file looks like the following:

.. code-block:: html

   <!doctype html>
   <html>
     <head>
       <!-- Add css and theme -->
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/slip.css">
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/theorem.css">
     </head>
     <body>

     <!-- This is the presentation -->
       <slip-slipshow>
         <!-- Add the slips here -->
       </slip-slipshow>

     <!-- Include the library -->
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/slipshow.cdn.min.js"></script>
       <!-- Start the presentation () -->
       <script>
         Slipshow.startSlipshow();
       </script>
     </body>
   </html>

..
   or in pug:

   .. code-block:: pug

   html
     head
       script(src="https://panglesd.github.io/slip-js/src/slipshow.js")
     body
       #rootSlip.root


..
   Create a file named ``myPresentation.html`` and copy-paste the minimal example.

Now open ``myPresentation.html`` with a browser, by double clicking on the file or selecting ``File > Open > "Your file"``. What do you see? Nothing! Let's inspect what is in the file.

.. code-block:: html

       <!-- Add css and theme -->
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/slip.css">
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/theorem.css">

Those lines include the rules to display the presentation. The first one is mandatory for the presentation, while the second one corresponds to the theme: the background color, how to display the title, the blocks and theorems...

.. code-block:: html

	<!-- This is the presentation -->
        <slip-slipshow>
          <!-- Add the slips here -->
        </slip-slipshow>

This delimits where the slips will be put. In this tutorial, we will (almost) only modify this part.

.. code-block:: html

     <!-- Include the library -->
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/slipshow.cdn.min.js"></script>
       <!-- Start the presentation () -->
       <script>
         Slipshow.startSlipshow();
       </script>

This is to include the library, and start the engine. Usually, you won't have to modify this.
		
Writing standard slips
-----------------------
In this section, we learn how to add slips. Everything will be added inside the ``slip-slipshow`` element, that is, inbetween the opening ``<slip-slipshow>`` and the closing ``</slip-slipshow>``:

.. code-block:: html

     <!-- This is the presentation -->
       <slip-slipshow>
         <!-- Add the slips here -->
       </slip-slipshow>


Adding a plain slip
^^^^^^^^^^^^^^^^^^^
Modify the file ``myPresentation.html`` to add the following slip:

.. code-block:: html

         <slip-slip immediate-enter>
           <slip-title>My first slip</slip-title>
           <slip-body>
	     <div>Here is the content of my first slip:</div>
	     <ul>
	       <li>A title</li>
	       <li>Some text</li>
	       <li>An itemized list</li>
	     </ul>
	   </slip-body>
	 </slip-slip>

Now save the file and reload the page in the browser. Suddenly there is something in the screen! Let us describe what each of these things mean.

* ``<slip-slip>...</slip-slip>`` defines the boundary of the new slip.
* the attribute ``immediate-enter`` ensures that the slips will be entered in order.
* ``<slip-title>...</slip-title>`` defines the title of the slip. Notice the french touch! (TODO: remove the french touch)
* ``<slip-body>...</slip-body>`` defines the body of the slip. It includes margin, padding,...

.. note:: If you don't include the ``<slip-body> ... </slip-body>``, the slip will have no margin. It can be usefull if you want to display something "fullscreen".
  
The rest is pure `html <https://www.w3schools.com/html/html_intro.asp>`_. You will need at least a small bit of understanding of html to be comfortable. But I do think that these skills are very useful in our world, and not so hard to learn! See the FAQ.

..
   For latex users, just translate your ``\begin{itemize}`` and ``\end{itemize}`` respectively into ``<ul>`` and ``</ul>``, and you ``\item`` into ``<li>...</li>``.

Making pauses
^^^^^^^^^^^^^

Add another slip, just after the closing tag of the previous one, with the following content:

.. code-block:: html

         <slip-slip immediate-enter>
           <slip-title>Question</slip-title>
           <slip-body>
	     <div>What do you think are my three favourite colors?</div>
	     <ul>
	       <li>Green</li>
	       <li>Orange</li>
	       <li>Apple</li>
	     </ul>
	     <div>And you?</div>
	   </slip-body>
	 </slip-slip>

Reload the page and push the right arrow. You see the new slip appearing. Suppose that we don't want to reveal directly the results, but we want to show them one by one. This is done with the pause mechanism. At each push of the right arrow, everything after a ``pause`` attribute is revealed, until the next ``pause``. Transform the list into this:

.. code-block:: html
		
	     <ul>
	       <li pause>Green</li>
	       <li pause>Orange</li>
	       <li pause>Apple</li>
	     </ul>

Reload and see what it does! It does what was expected.

.. warning:: You should never let some plain text be in a slip, otherwise the "pause" mechanism won't work for it! This is because css styling cannot be made to text node. For instance, try to move the "And you?" outside of a div, it won't be affected by the pause.

Emphasizing
^^^^^^^^^^^^^

It is common in presentation to emphasize or highlight some words. The following slip shows how it works in slip-js, add it after the last one.

.. code-block:: html

         <slip-slip immediate-enter>
           <slip-title>Emphasizing</slip-title>
           <slip-body>
	     <div>I have <span emphasize-at="1 4">nothing to say</span> but my <span emphasize-at="2 4">words</span> are <span emphasize-at="3 4">important</span>!</div>
	   </slip-body>
	 </slip-slip>

This is pretty self-explanatory! When the attribute ``emphasize-at`` is set to a list of numbers separated by spaces, for instance ``emphasize-at="1 4"``, the content will be emphasized exactly at these steps, that is, step 1 and 4 in the example. There are several other ways to emphasize depending on the need, such as ``mk-emphasize-at``, or soonish ``emphasize-at-unpause``, see the :ref:`listAttributes`.

Stating theorems
^^^^^^^^^^^^^^^^^
To state a theorem, juste create a ``div`` with the right class, that is either ``block``, ``definition``, ``theorem`` or ``example``. You can also give a title with the attribute ``title``.

For instance, add the following slip to your presentation and reload it.

.. code-block:: html
		
      <slip-slip immediate-enter>
        <slip-title>Blocks</slip-title>
        <slip-body>
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
	</slip-body>
      </slip-slip>

Writing Math
^^^^^^^^^^^^^^^^^

If you need to write mathematics, there are two very good options you can use: Mathjax and Katex. Both can be used with slipshow. You can follow their tutorial, or just add the following line to your file:

.. code-block:: html

   <script type="text/javascript" id="MathJax-script" async
      src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
   </script>

inside the ``head`` tag. Then, you can write mathematics like this: ``\( \sqrt{2} \)`` for inline and ``\[\bigcup_{n} E_n\]`` for math blocks.

The rest of this section concerns only the people who want to work without internet access. If you downloaded the archive containing the library, it already contains eerything you need to write math using mathjax. If you used ``npm`` to install the library, install  ``mathjax`` or ``katex``  using:

.. code-block:: bash

   $ npm install mathjax@3

and then link the library using

.. code-block:: html

   <script src="node_modules/mathjax/es5/tex-chtml.js" id="MathJax-script" async></script>

This line is automatically added if you generated you minimal file using:

.. code-block:: bash
		
   $ npx new-slipshow --mathjax-local > name-of-slipshow-file.html
   
Using the full power of slips
-----------------------------

Until now, we have only used the "classic" part of slideshow presentation. Slip allows some more things!

Moving the point of view
^^^^^^^^^^^^^^^^^^^^^^^^

Sometimes, you need to show things below the bottom of the slip. You can do this by using one of the attribute ``top-at``,  ``center-at``,  ``bottom-at``, which moves the screen to make the element be at the top (respectively center, bottom) of the screen.

For instance, copy paste this new slip and test the attributes ``down-at``.

.. code-block:: html
		
      <slip-slip immediate-enter>
        <slip-title>Blocks</slip-title>
        <slip-body>
	  <div class="block" title="Lispum">
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus auctor sem a libero ultricies convallis. Sed hendrerit tellus mi, malesuada lacinia turpis blandit sit amet. Aliquam auctor metus eu massa imperdiet, vel scelerisque metus aliquet. Nulla facilisi. Aliquam erat volutpat. Aenean nec lacus eu massa lacinia ultricies. In eget sollicitudin eros, sed suscipit elit. Quisque ac scelerisque purus, sit amet sodales est. Curabitur efficitur ultrices nunc. Mauris aliquet nisi commodo nulla condimentum, sed tempor nisi suscipit. Quisque magna augue, ultricies eu commodo ut, fringilla ac erat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Morbi pharetra felis rutrum mi vehicula dapibus. Aliquam sem mi, fringilla ut facilisis efficitur, efficitur vel odio.
	  </div>
	  <div down-at="1">
	    That was long!
	  </div>
	</slip-body>
      </slip-slip>


Acting at unpause
^^^^^^^^^^^^^^^^^^^^^^^^

Until now, we have seen two mechanisms: the "pause" mechanism, which allows to make things appear one by one, and the "absolute" mechanism, where we specify the step number where things are emphasized or "moved to".

The "absolute" mechanism allows more control, however it is sometimes heavier to work with it. Indeed, slips can become quite long, and if you want to add one step at the beginning, you might have to change every ``emphasize-at`` and ``down-at`` values to increment them by one, by hand.

However, there is a way to couple the "pause" mechanism with other actions than pauses, using the ``*-at-unpause``, where ``*`` can be multiple things, for instance ``down-at-unpause``.

.. code-block:: html
		
      <slip-slip immediate-enter>
        <slip-title>Déclaration des droits de l'Homme et du Citoyen</slip-title>
        <slip-body>
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
	</slip-body>
      </slip-slip>

.. tip:: You can make the ``*-at-unpause`` act on another element by specifying its ``id`` as value of the attribute. For instance, ``<div pause center-at-unpause="thm1">...</div>``, ``<div id="thm1" class="theorem">...</div>`` will center the window around the theorem when the first ``div`` is unpaused.

.. tip:: If a slip has many steps, and you want to go directly to the next one, you can hold ``Shift`` while you press the right arrow. It will go through all steps until the next slip.

.. todo:: The attribute ``emphasize-at-unpause`` is not yet implemented but it will be very soon!


Subslips of slips
^^^^^^^^^^^^^^^^^^^^^^^^

In slips-js, a presentation is not anymore linear, but has rather the shape of a tree. So a slip can easily contain slips inside itself!

Consider the following example, that you can add as a new slip:

.. code-block:: html

      <slip-slip immediate-enter>
          <slip-title>A review of the numbers</slip-title>
          <slip-body>
	      <div>First, we consider the positive numbers</div>
	      <div style="display: flex; justify-content: space-around;">
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The integer</slip-title>
		      <slip-body>
			  <ul>
			      <li>1 is an integer,</li>
			      <li pause>2 is an integer,</li>
			      <li pause>100 is an integer.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The rationnals</slip-title>
		      <slip-body>
			  <ul>
			      <li>1/2 is a rational,</li>
			      <li pause>2/3 is a rational,</li>
			      <li pause>567/87 is a rational.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The reals</slip-title>
		      <slip-body>
			  <ul>
			      <li>π is a real,</li>
			      <li pause>e is a real,</li>
			      <li pause>d is a real.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
	      </div>
	      <div pause>Then, the negative one</div>
	      <div style="display: flex; justify-content: space-around;">
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The integer</slip-title>
		      <slip-body>
			  <ul>
			      <li>-1 is an integer,</li>
			      <li pause>-2 is an integer,</li>
			      <li pause>-100 is an integer.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The rationnals</slip-title>
		      <slip-body>
			  <ul>
			      <li>-1/2 is a rational,</li>
			      <li pause>-2/3 is a rational,</li>
			      <li pause>-567/87 is a rational.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
		  <slip-slip delay="1" scale="0.25" auto-enter>
		      <slip-title>The reals</slip-title>
		      <slip-body>
			  <ul>
			      <li>-π is a real,</li>
			      <li pause>-e is a real,</li>
			      <li pause>-d is a real.</li>
			  </ul>
		      </slip-body>
		  </slip-slip>
	      </div>
	  </slip-body>
      </slip-slip>


In this example, there are several new things:

* The flexbox ``div`` container is just plain css to make the subslips well aligned,
* The ``scale`` attribute scales the slip. It is better than a css transform as not only the rendering is smaller, but also the size.
* The ``delay`` attribute make the camera move slowly to enter the slip.

.. note:: The difference between ``immediate-enter`` and ``auto-enter`` is that a slip with ``immediate-enter`` will be entered before the pause, while ``auto-enter`` will be entered after one stop.

.. note:: The transition back to the parent slip is not very good at this point. This is because the parent slip has ``delay="0"`` by default. We wanted this as we do not want to enter this slip "smoothly" the first time. We will see in Javascripting your presentation how to modify this.

Focusing on elements
^^^^^^^^^^^^^^^^^^^^^^^^

Another important feature of slipshow is that it allows easily to focus on element of a slip. For instance, add the following more or less self-explanatory slip to you slipshow:

.. code-block:: html

      <slip-slip immediate-enter>
        <slip-title>A table</slip-title>
	<slip-body>
	  <table>
	    <tr unfocus-at="5">
	      <td focus-at="1"> Here is some other text </td>
	      <td focus-at="4"><img src="https://picsum.photos/200"/></td>
	    </tr>
	    <tr>
	      <td focus-at="2"><img src="https://picsum.photos/200"/></td>
	      <td focus-at="3"> Here is some text </td>
	    </tr>
	  </table>
	</slip-body>	
      </slip-slip>

.. note:: It is not important which element has the attribute ``unfocus-at``.
      
The table of content
^^^^^^^^^^^^^^^^^^^^^^^^

When you press ``t`` during your presentation. Magic! However, this is quite ugly... and will be improved shortly. You can first add a ``toc-title`` attribute to each of the slips so that they get a name in the table of content.

.. code-block:: html

      <slip-slip immediate-enter toc-title="Name that will appear in the table of content">

.. todo:: The way the table of content looks like will very likely change a lot, please tell me how you would like it to be.

Scripting your presentation
--------------------------------

One of the advantage of slip is that you can make animation. In order to start your animation or any special events, you will have to execute javascript at some steps.

Executing Javascript in the flow
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Following other events, there are two ways to execute javascript: with the ``exec-at`` and the ``exec-at-unpause`` attributes. You need to enclose the script you want to execute inside script tags, with type ``slip-script``.

.. code-block:: html

		<script type="slip-script">
		  // Your script here, with variable "slip"
		</script>

For instance, recall that the delay for the slip named "A review of the numbers" was set to 0, but when we leave the subslips, we want it to be 1. Just insert wherever in the corresponding slip (but not in a subslip) the following code:

.. code-block:: html

		<script type="slip-script" exec-at="1">
		  slip.currentDelay = 1;
		</script>

..
   However, one should be very careful when making javascript changes. Indeed, slip cannot automatically (yet) revert your scripts, and if you go back in the presentation you should make sure they are reverted at step 0. For instance, in our case:

   .. code-block:: html

		   <script type="slip-script" exec-at="0">
		     slip.delay = 0;
		   </script>
		   <script type="slip-script" exec-at="1">
		     slip.delay = 1;
		   </script>

		
Program your presentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let us now focus on the second part of the file: the Javascript. Although it is not necessary to modify it, in some special cases you might need to change a few things.

.. code-block:: html

       <script>
         Slipshow.startSlipshow();
       </script>

Modifying this part is more advanced, as it requires to know a bit of javascript, and thus somehow out of the scope of a tutorial. It is still possible to understand the following if you now a bit of computer programming. We will consider the following scenario: we just want to programmatically specify the order of the slips. This way, it is very easy to skip a part by just commenting a few lines,, if you want to have a "light" version of your presentation, or to change the order of the slips.

Start by removing the attributes ``immediate-enter``, and replace them by an ``id``. For instance, the lines starting the first few slips might look like this:

.. code-block:: html

      <slip-slip id="content-first-slip" toc-title="My First Slip">
      <slip-slip id="question" toc-title="A question about colors">
      <slip-slip id="emphasizing" toc-title="How to emphasize when you are shy">
      <slip-slip id="block" toc-title="Meta Definitions, Meta Theorems">
      <slip-slip id="latin" toc-title="Latin Overflow">

Now, instead of ``Slipshow.startSlipshow();`` in the ``script`` tag, put the following lines:

.. code-block:: javascript

   // Slipshow.startslipshow() create a slipshow engine and starts
   // it, with slips that have immediate-enter or auto-enter attributes
   // We commented this line because we want to specify the slips before
   // starting the slipshow
   
   // Slipshow.startSlipshow();

   // We first create a slip engine inside the element "rootSlip"
   let engine = new Slipshow.Engine("rootSlip");
   // We get the root Slip of the presentation (remember that a slipshow is a tree)
   let rootSlip = engine.getRootSlip()

   // We create the slips we want to add as subslips of the root
   let firstContentSlip = new Slipshow.Slip("content-first-slip", null, [], engine, {})
   let questionSlip = new Slipshow.Slip("question", null, [], engine, {})
   let emphasizingSlip = new Slipshow.Slip("emphasizing", null, [], engine, {})
   let blockSlip = new Slipshow.Slip("block", null, [], engine, {})
   let latinSlip = new Slipshow.Slip("latin", null, [], engine, {})

   // We add the subslips to the root
   rootSlip.setAction([
       firstContentSlip,
       questionSlip,
       emphasizingSlip,
       blockSlip,
       latinSlip,
       ]);

   // We start the engine
   engine.start();
   
It is now very easy to mess with the order of the slips. It is also possible add actions instead of subslips. For instance, if you want to add an alert, reverse the order of the slips and omit the emphasizing slip, replace ``rootSlip.setAction([...])`` by:

.. code-block:: javascript

   rootSlip.setAction([
       latinSlip,
       (slip) => { alert(); }
       blockSlip,
       // emphasizingSlip,
       questionSlip,
       firstContentSlip,
       ]);


Changing the shortcuts
^^^^^^^^^^^^^^^^^^^^^^^^

.. todo:: If have to make this easily possible...
