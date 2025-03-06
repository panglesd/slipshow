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

Your presentation has been compiled to a standalone file named ``my-first-slipshow.html``! You can open it in your favorite browser to see the result. You can send the file to anyone, they can open it and it will work, even without internet connection!

For a description of the syntax, you can read the syntax reference. For a tutorial on the many features of slipshow, you can have a look at the tutorial.
