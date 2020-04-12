.. _getting-started:

Getting Started
===============

Slip.js is a library for displaying slips. This section explains how to start writing your slips. Here are the different possibilities:

* You want to start right away and you will have access to internet when displaying your slips. Then, you should go for the CDN (Content Delivery Network) solution, where you do not have to download anything, the library will just have to be linked in the file.
* You want to have everything local to be able to work or show your slips without internet access, but you want to keep it simple. In this case, you should just download the archive containing all you need.
* You want to have everything local and include your own javascript libraries, or use some advanced features (that will be added later). In this case you should go for the ``npm`` install.

  
..
   In case you want simplicity and have an access to internet, you should choose the CDN option and start reading the :ref:`tutorial`. If you want to work with everything local, you have several options: either download the library, use github or use npm.


..
   You can also install slip-js it using npm.

Using a Content Delivery Network
--------------------------------

A Content Delivery Network, or CDN, is a network of server that will serve the library. If you use this option, you will be able to start writing your slips right away, the library will be downloaded when needed. The drawback of this is that you cannot see your slips without internet access.

Recall that a slip presentation is just an ``html`` file. Therefore, a minimal presentation (using a CDN) will just look like this:

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
       <div class="root" id="rootSlip">
         <!-- Add the slips here -->
       </div>

     <!-- Include the library -->
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/slipshow.cdn.min.js"></script>
       <!-- Start the presentation () -->
       <script>
         Slipshow.startSlipshow();
       </script>
     </body>
   </html>

The part that includes the library are the following:

.. code-block:: html

       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/slip.css">
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/css/theorem.css">
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slipshow@gh-pages/slipshow.cdn.min.js"></script>

The first line define the style of your presentation requires by slip. The second line is a theme for your presentation, you can choose one from this list or even write your own theme. The last line is the library itself. You can now read the :ref:`tutorial`!

Installing a local version
--------------------------

Downloading an archive
^^^^^^^^^^^^^^^^^^^^^^

Download the latest release here: `slipshow.tar.gz <https://panglesd.github.io/slipshow/slipshow.tar.gz>`_.
Then unpack the archive:

.. code-block:: bash

   tar xvf slipshow.tar.gz

You are already ready to go. You still might want to modify the directory name.

.. code-block:: bash

   mv slipshow my_presentation_name

You can now modify the file in the directory called ``slideshow.html``, and open it in a browser to see the result.

Using npm
^^^^^^^^^^^^^^^^^^^^^^
To install slipshow, go into an empty directory where you want to write your presentation. In this directory, just type:

.. code-block:: bash

   npm install slipshow

This install the slipshow engine. If you want to add math support (slipshow also work with katex), you have to add:

.. code-block:: bash

   npm install mathjax

Now, to create a new file with a template presentation, type:

.. code-block:: bash

   npx new-slipshow > name_of_your_file.html
.. code-block:: bash

   npx new-slipshow --mathjax > name_of_your_file.html

Open ``name_of_your_file.html`` in an editor to start writing you presentation, and in browser to see it!

