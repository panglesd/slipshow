.. _getting-started:

Getting Started
===============

Slip.js is a library for displaying slips. This section explains how to start writing your slips. In case you want simplicity and have an access to internet, you should choose the CDN option and starts reading the :ref:`tutorial`. If you want to work with everything local, you have several options: either download the library, use github or use npm.

.. todo:: I will need to prepare slip for local use before writing those parts!

..
   You can also install slip-js it using npm.

Using a Content Delivery Network
--------------------------------

A Content Delivery Network, or CDN, is a network of server that will serve the library. If you use this option, you will be able to start writing your slips right away, the library will be downloaded when needed. The drawback of this is that you cannot see your slips without internet access.

Just include the ``css`` and ``js`` files in the main ``html`` file with:

.. code-block:: html

       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/css/slip.css">
       <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/css/theorem.css">
       <script src="https://cdn.jsdelivr.net/gh/panglesd/slip-js@gh-pages/slip-lib.cdn.min.js"></script>

If you don't know where to put these lines, read the :ref:`tutorial`!

Installing a local version
--------------------------

Downloading an archive
^^^^^^^^^^^^^^^^^^^^^^

Download a release when there will be one, and include the files as it will be explained here.

Usig github
^^^^^^^^^^^^^^^^^^^^^^

Clone the repo, install, build and link. You can also modify examples.

Using npm
^^^^^^^^^^^^^^^^^^^^^^
To install slip-js, just type

.. code-block:: bash

   npm install slip-js

However, this won't work as we haven't yet released the first version of slip.
