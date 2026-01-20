==========================
The Command Line Interface
==========================

The best way to learn about the command line interface for Slipshow is to just run:

.. code-block::

   $ slipshow --help

This page only contains minimal information for those who want a quick tour of the CLI.

The CLI contains 4 subcommands: ``compile``, ``serve``, ``markdown`` and ``themes``.

Compile
-------

The ``compile`` subcommand allows to compile your input file into a standalone html file. It contains the usual flags such as ``-o``, allows you to specify your theme, the dimension for your presentation. It also allows to watch the files your presentation depends on for changes and recompilation.

To learn more about this subcommand, run:

.. code-block::

   $ slipshow compile --help

Serve
-----

The ``serve`` subcommand is similar to the ``compile`` subcommand, but it also starts a server on which you'll be able to see your presentation and automatically reload it when a file is changed. It takes mostly the same flags as ``compile`` but can also specify the port.

To learn more about this subcommand, run:

.. code-block::

   $ slipshow serve --help

Markdown
--------

The ``markdown`` subcommand allows to turn the input file into a standalone, valid Markdown file. It can be useful as a first step for converting your presentation into something else.

To learn more about this subcommand, run:

.. code-block::

   $ slipshow markdown --help

Themes
------

The ``themes`` subcommand allows you to manage the themes for Slipshow. Currently, it only allows you to list the official themes you can use. In the future, you'll be able to add and manage your own themes.

To learn more about this subcommand, run:

.. code-block::

   $ slipshow themes --help
