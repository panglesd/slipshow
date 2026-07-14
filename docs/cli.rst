==========================
The Command Line Interface
==========================

The best way to learn about the command line interface for Slipshow is to run:

.. code-block::

   $ slipshow --help

This page contains only minimal information for those who want a quick tour of the CLI.

.. note::

   CLI options can also be set through :doc:`frontmatter` in your presentation files.

The CLI contains 4 commands: ``compile``, ``serve``, ``markdown`` and ``themes``.

Compile
-------

The ``compile`` command compiles your input file into a standalone HTML file. It contains the usual flags such as ``-o``, allows you to specify your theme, the dimensions of your presentation, and so on. It can also watch the files your presentation depends on and automatically recompile your presentation when they change.

To learn more about this command, run:

.. code-block::

   $ slipshow compile --help

Serve
-----

The ``serve`` command is similar to the ``compile`` command, but it also starts a server on which you'll be able to see your presentation and automatically reload it when a file is changed. It takes mostly the same flags as ``compile`` but can also specify the port number it listens on.

To learn more about this command, run:

.. code-block::

   $ slipshow serve --help

Markdown
--------

The ``markdown`` command converts the input file into a valid, standalone Markdown file. It can be useful as a first step for converting your presentation into something else.

To learn more about this command, run:

.. code-block::

   $ slipshow markdown --help

Themes
------

The ``themes`` command manages Slipshow's themes. Currently, it only allows you to list the official themes you can use. In the future, you'll be able to add and manage your own themes.

To learn more about this command, run:

.. code-block::

   $ slipshow themes --help
