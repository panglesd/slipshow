.. _getting-started:

============
Installation
============

There are different ways to have access to the slipshow compiler:

**The best option** for people comfortable with it is to use the command line interface. It is distributed through various mediums:

- You can download :ref:`precompiled binaries<Precompiled binaries>` for Mac and Linux, and Windows through WSL
- Slipshow is packaged in the ``opam`` package manager, if you have it all it takes is ``opam install slipshow``.
- You can always :ref:`compile from source<compiling from source>`!

For **online-only use**, consider the :ref:`online sliphub editor<the sliphub online editor>`. It is great for trying the tool but is currently limited, for instance for anything that requires multiple files.

There are other options that currently are lagging behind in terms of version, but that I might revisit some day: the :ref:`VSCode extension<The VS Code plugin>` and the slipshow editor.

Precompiled binaries
====================

Precompiled binaries are available to download in the `release
<https://github.com/panglesd/slipshow/releases/latest>`_ page of the
project. Save the file corresponding to your architecture, and make it available
by moving to a directory included in your ``$PATH``, e.g. ``/usr/local/bin``.

Note that Mac user needs to have a homebrew installation until `this bug <https://github.com/panglesd/slipshow/issues/145>`_ is fixed. They also need some libraries, eg ``libffi``.

You can test that the ``slipshow`` binary is available by running:

.. code-block:: shell

   $ slipshow --help

If the help shows up, you successfully installed slipshow!

Using ``opam``
==============

Slipshow is packaged in the default ``opam`` repository so you can install it simply with

.. code-block:: shell

   $ opam install slipshow

You can test that the ``slipshow`` binary is available by running:

.. code-block:: shell

   $ slipshow --help

If the help shows up, you successfully installed slipshow!
If, even after ``opam`` claims to have successfully installed it, ``slipshow`` is not available, it might be that you need to do:

.. code-block:: shell

   $ eval $(opam env)

This updates your environment to include the packages installed by ``opam``.

The sliphub online editor
=========================

The `sliphub online editor <https://sliphub.choum.net/new>`_ is a quick way to
try out slipshow, as it does not require any setup. This link will open a page with
an editor on the left, and a preview on the right.

Currently, the interface is quite minimal. Your progress is saved "live" and you
can even do collaborative editing: two people editing the same document.

Remember the link to be able to come back to your document later! And save your
work locally: This is still experimental.

The VS Code plugin
==================

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

Compiling from source
=====================

Follow the instructions available in the ``CONTRIBUTING.md`` file on the `github repository <https://github.com/panglesd/slipshow>`_.

Upgrading
=========

Upgrading is made just by repeating the installation process when a new version is available.

If you are using a new version to compile an old presentation, make sure to read the release notes and fully verify the output before presenting! Slipshow has not yet reached a stable state and releases often contains small breaking changes (most of the time, easy to fix).
