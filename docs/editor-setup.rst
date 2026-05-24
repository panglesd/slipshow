============
Editor Setup
============

Slipshow can be integrated into your editor for a better experience when
preparing your presentation.

This integration helps in several ways:

- It helps you write a valid input file, by:

  - displaying errors directly in your editor,
  - offering autocompletion when applicable,
  - showing documentation for actions on hover,
  - jumping to definition of identifiers

- It also allows you to see a preview of your presentation, updated in real time
  as you type.
- It compiles your presentation on save.

This integration is still in its early days. It is going to be improved and
extended with new releases of slipshow.

Emacs
=====

You need two modes to develop slipshow presentations comfortably in emacs:

- `markdown-mode <https://github.com/jrblevin/markdown-mode>`_, a major mode for
  editing markdown document with syntax highlighting, and other facilities.
- ``eglot``, a generic LSP client (part of emacs, so nothing to install) for the
  rest of the integration.

After opening your input ``.md`` file, type ``M-x eglot`` to start ``eglot``,
which will prompt you the command to start the lsp server. At this point, type
``slipshow lsp`` (you need ``slipshow`` to be installed of course).

The command above sets you for editor features such as errors, documentation on
hover, etc, but it also starts a preview server, usually accessible by opening a
browser and going to ``localhost:8080``. However, if the port ``8080`` is taken,
slipshow might use another port. In any case, it sends a notification with the
address to use, so check your minibuffer or the ``*Messages*`` buffer.

.. note::

   If your presentation is split in multiple files, you don't need to start
   eglot for each of the files, as long as they are in the same folder. If they
   are in different folder, emacs has to be able to recognize "the root of the
   project" for it to work. It can do so by looking for a specific file or
   folder that defines a project root. A predefined one is ``.git``, so adding a
   git repository to your root folder is enough. Another option is to customize
   "Project Vc Extra Root Markers" to add for instance ``.slipshow`` and create
   a ``.slipshow`` file at the root.

VSCode
======

Slipshow currently has an official VSCode extension. *However*, unfortunately,
it has not yet been updated to support the new LSP server. This is ongoing work
that is going to be included hopefully soon.

In the meantime, you can use a generic LSP server. Since VSCode does not provide
an official one, I can say that `"Generic LSP Proxy"
<https://open-vsx.org/extension/mjmorales/generic-lsp-proxy>`_ works at least
for displaying errors. Start it with the command palette, the first time using
``LSP Proxy: Initialize LSP Configuration`` and answer its follow up questions
as:

- Use a custom configuration
- ``slipshow`` for the language ID
- ``slipshow`` for the name of the command
- ``.md`` for the extension of the files
- ``stdio`` for the transport type
- ``lsp`` for the argument to the command

Now that the LSP is configured, next time you can launch it simply with ``LSP
Proxy: Restart LSP server``.

.. note::

   If you want a simpler setup, and don't need the latest version of slipshow,
   you can still use the official slipshow extension, installable from the
   marketplaces.

Other editors
=============

As long as your editor supports editing of markdown files, and the LSP protocol,
you are good. Just start your LSP server with the command ``slipshow lsp``!

And please `contribute to the docs
<https://github.com/panglesd/slipshow/issues>`_ if you can improve it!
