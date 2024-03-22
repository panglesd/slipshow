.. _getting-started:

=================
 Getting Started
=================

Installation
============

There are different ways to have access to the slipshow compiler:

- **VSCode user**: Use the :ref:`VSCode extension<The VS Code plugin>`.
- **Linux or Mac user**, reasonably comfortable with the command line: Use
  :ref:`precompiled binaries<Precompiled binaries>`.
- For **online-only use**, consider the :ref:`online sliphub editor<the sliphub online editor>`.
- Otherwise, use the :ref:`slipshow editor<the slipshow editor>`.

In addition to this, for advanced users, you also have the following options:

- You can always :ref:`compile from source<compiling from source>`! This solution is convenient
  for ``opam`` users.
- A :ref:`javascript version<using npm>` of the slipshow compile is distributed through npm. It lacks some features but might be useful in some setups

..
   .. contents:: Installation methods
     :local:

The VS Code plugin
------------------

The VS Code plugin can be downloaded from the `official marketplace
<https://marketplace.visualstudio.com/items?itemName=Slipshow.slipshow>`_ as
well as from `open VSX
<https://open-vsx.org/extension/Slipshow/slipshow>`_. This means that searching
the ``slipshow`` extension directly from within VS Code should yield a result in
most cases!

The VS Code plugin provides two commands:
- Compile presentation. Open the command palette, and type "Compile slipshow". This should compile the presentation in a ``.html`` of the same name.
- Preview presentation.  Open the command palette, and type "Preview
slipshow". This should open a new window with a live preview of your
presentation!

Precompiled binaries
--------------------

Precompiled binaries are available to download in the `release
<https://github.com/panglesd/slipshow/releases/latest>`_ page of the
project. Save the file corresponding to your architecture, and make it available
by moving to a directory included in your ``$PATH``, eg ``/usr/local/bin``.

You can test that the ``slipshow`` binary is available by running:

.. code-block:: shell

   $ slipshow --help

If the help shows up, you successfully installed slipshow!

Then, you can use ``slipshow`` to compile your documents:

.. code-block:: shell

   $ slipshow presentation.md            # Compiles to `presentation.html`
   $ slipshow --serve presentation.md    # Compiles to `presentation.html` and serves a live-preview on 127.0.0.1:8080


The sliphub online editor
-------------------------

The `sliphub online editor <https://sliphub.choum.net/new>`_ is a quick way to
try out slipshow, as it does not require any setup. This link will open a page with
an editor on the left, and a preview on the right.

Currently, the interface is quite minimal. Your progress is saved "live" and you
can even do collaborative editing: two people editing the same document.

Remember the link to be able to come back to your document later! And save your
work locally: This is still experimental.

The slipshow editor
-------------------

The slipshow editor is an editor specialized in writing slipshow
presentations. It provides live-previewing of your presentation.

However, since the project is very new compared to most editors, you might miss
features from eg VS Code, Emacs or Vim.

Compiling from source
---------------------

This requires ``opam``.

Run the following command:

.. code-block:: shell

   $ opam pin slipshow git+https://github.com/panglesd/slipshow.git
   $ # test your installation:
   $ slipshow --help


and you are done!

Using npm
-------------

For a reason described below, installing slipshow through npm will install a slightly slower version, with less functionalities. So, installing it like that is somehow discouraged, unless you don't mind the missing functionalities!

.. code-block:: shell

   $ npm install slipshow
   $ # Test your installation
   $ npx slipshow -- --help

So, here are the limitations of the npm version of slipshow:
- It is slower (might not be a problem, since it still is very fast!)
- The ``--watch`` argument is not (yet) available. This argument lets slipshow compiler run in watch mode, every file modifications triggering a recompilation. You can use ``inotifywait`` ou ``fswatch`` to mimick the behaviour!
- The ``--serve`` argument is not (yet) available. This argument lets slipshow serve the file through an http server, and provide live-reloading on file changes! You can use the ``live-reload`` npm package to mimick the behaviour.

The reason for such limitations is that slipshow is written in OCaml, not javascript. Luckily, OCaml can compile to javascript! But for some functionalities, like file-watching (which relies on a C library), this compilation cannot be meaningful.

Your first presentation
=======================

Copy and paste the following example file in ``my-first-slipshow.md``:

.. code-block:: markdown

		# My first presentation!

		Here is a paragraph.

		{pause}

		- some items
		- and some others!

		{.definition pause up}
		This is a definition


This is the source file that you can edit when writing your presentation. For the syntax, see the syntax reference.

Now, compile the file:

.. code-block:: shell

		$ slipshow my-first-slipshow.md
		$ # or npx slipshow my-first-slipshow.md if you installed it through npm

Your presentation has been compiled to a standalone file named ``my-first-slipshow.html``! You can open it in your favorite browser to see the result. You can send the file to anyone, they can open it and it will work, even without internet connection!

For a description of the syntax, you can read the syntax reference. For a tutorial on the many features of slipshow, you can have a look at the tutorial.


..
   * You want to start right away and you will have access to internet when displaying your slips. Then, you should go for the CDN (Content Delivery Network) solution, where you do not have to download anything, the library will just have to be linked in the file.
   * You want to have everything local to be able to work or show your slips without internet access, but you want to keep it simple. In this case, you should just download the archive containing all you need.
   * You want to have everything local and include your own javascript libraries, or use some advanced features (that will be added later). In this case you should go for the ``npm`` install.

  
..
   In case you want simplicity and have an access to internet, you should choose the CDN option and start reading the :ref:`tutorial`. If you want to work with everything local, you have several options: either download the library, use github or use npm.


..
   You can also install slip-js it using npm.
..

   ..
      Using a Content Delivery Network
      --------------------------------

   ..
      A Content Delivery Network, or CDN, is a network of server that will serve the library. If you use this option, you will be able to start writing your slips right away, the library will be downloaded when needed. The drawback of this is that you cannot see your slips without internet access.

      Recall that a slip presentation is just an ``html`` file. Therefore, a minimal presentation (using a CDN) will just look like this:

      .. code-block:: html

	 <!doctype html>
	 <html>
	   <head>
	     <!-- Add css and theme -->
	     <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/dist/css/slip.css">
	     <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/dist/css/theorem.css">
	   </head>
	   <body>

	   <!-- This is the presentation -->
	     <slip-slipshow>
	       <!-- Add the slips here -->
	     </slip-slipshow>

	   <!-- Include the library -->
	     <script src="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/dist/slipshow.cdn.min.js"></script>
	     <!-- Start the presentation () -->
	     <script>
	       Slipshow.startSlipshow();
	     </script>
	   </body>
	 </html>

      The part that includes the library are the following:

      .. code-block:: html

	     <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/css/slip.css">
	     <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/css/theorem.css">
	     <script src="https://cdn.jsdelivr.net/npm/slipshow@0.0.17/slipshow.cdn.min.js"></script>

      The first line define the style of your presentation requires by slip. The second line is a theme for your presentation, you can choose one from this list or even write your own theme. The last line is the library itself. You can now read the :ref:`tutorial`!

      Installing a local version
      --------------------------

      Downloading an archive
      ^^^^^^^^^^^^^^^^^^^^^^

      Download the latest release here: `slipshow.tar.gz <https://panglesd.github.io/slipshow/slipshow.tar.gz>`_.
      Then unpack the archive:

      .. code-block:: bash

	 $ tar xvf slipshow.tar.gz

      You are already ready to go. You still might want to modify the directory name.

      .. code-block:: bash

	 $ mv slipshow my_presentation_name

      You can now modify the file in the directory called ``slideshow.html``, and open it in a browser to see the result.

      Using npm
      ^^^^^^^^^^^^^^^^^^^^^^
      To install slipshow, go into an empty directory where you want to write your presentation. In this directory, just type:

      .. code-block:: bash

	 $ npm install slipshow

      This install the slipshow engine. If you want to add math support (slipshow also work with katex), you have to add:

      .. code-block:: bash

	 $ npm install mathjax

      If you want all the scripts from slipshow to work, for instance to be able to manage your tikz figures, you need a file describing the project. Using this file, the scripts will know the root of the project. To create it, run:

      .. code-block:: bash

	 $ npm init

      Now, to create a new file with a template presentation, type:

      .. code-block:: bash

	 $ npx new-slipshow > name_of_your_file.html

      or, if you need to write math:

      .. code-block:: bash

	 $ npx new-slipshow --mathjax-local > name_of_your_file.html

      Open ``name_of_your_file.html`` in an editor to start writing you presentation, and in browser to see it!

