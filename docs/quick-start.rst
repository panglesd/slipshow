Getting Started
===============

Slip.js is a library for displaying slips. The easiest way is to include the library using a CDN, however in this case you will not be able to display your slips without internet access.

You can also install slip-js it using npm.

Using a CDN
-----------

The minimal example of a slip presentation is the following:

.. code-block:: html

   <!doctype html>
   <html>
     <head>
       <script src="https://panglesd.github.io/slip-js/src/slip-lib.js"></script>
     </head>
     <body>
       <div class="root" id="rootSlip">
       </div>
     </body>
   </html>

or in pug:

.. code-block:: pug

   html
     head
       script(src="https://panglesd.github.io/slip-js/src/slip-lib.js")
     body
       #rootSlip.root

Installing a local version
--------------------------

To install slip-js, just type

.. code-block:: bash

   npm install slip-js

However, this won't work as we haven't yet released the first version of slip.
