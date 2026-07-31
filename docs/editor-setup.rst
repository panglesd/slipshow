============
Editor Setup
============

Slipshow should be integrated into your editor for a better experience when
preparing your presentation.

This integration helps in several ways:

- It helps you write a valid input file, by:

  - displaying errors directly in your editor,
  - offering autocompletion when applicable,
  - showing documentation for actions on hover,
  - jumping to identifier definitions

- It also allows you to see a preview of your presentation, updated in real time
  as you type.
- It compiles your presentation on save.

This integration is still in its early days, but it will be improved and
extended alongside new releases of Slipshow.

Emacs
=====

Slipshow's emacs has few dependencies:

- Emacs needs to be at least of version 29.1.
- `markdown-mode <https://github.com/jrblevin/markdown-mode>`_, a major mode for
  editing markdown document with syntax highlighting, and other facilities. You
  should have it already if you edit markdown files, otherwise install it, for
  instance with ``M-x package-install <ret> markdown-mode <ret>``.
- ``eglot``, a generic LSP client (part of emacs, so nothing to install) for the
  rest of the integration.

You can install it by adding these lines to your ``.emacs`` file:

.. code-block::

   (use-package slipshow-mode
     :vc (:url "https://github.com/panglesd/slipshow-emacs-mode" :rev :newest))

Slipshow's mode is a major mode automatically activated on ``.slp``
files. Whenever it is activated, it will start a preview server for the project
the file is in (you need ``slipshow`` to be installed of course). The server's
address is communicated through the minibuffer, but it usually is
``http://localhost:8080``.

The slipshow major mode also sets up editor features such as errors,
documentation on hover, etc. It currently features two commands:
``slipshow-preview-go-next`` and ``slipshow-preview-go-previous``, to control
the presentation's step from the editor.

Moreover, you can configure whether you want the preview to be updated on save,
or on each key stroke, using the ``slipshow-refresh-on`` variable (that you can
customize through the ``customize`` interface).

.. note::

   If your presentation is split into multiple folders that are not recognized
   by emacs as the same project, two preview servers might be started, and
   things will break. Emacs finds a project by looking upward for a "root" file
   or folder. A predefined root is a ``.git`` folder, so adding a git repository
   to your root presentation folder is enough (and probably good
   practice!). Another option is to customize "Project Vc Extra Root Markers" to
   add for instance ``.slipshow`` and create a ``.slipshow`` file at the root.

VSCode
======

Slipshow currently has an official VSCode plugin, available in several plugin
stores: in the `"Visual Studio Code Marketplace" <https://marketplace.visualstudio.com/items?itemName=Slipshow.slipshow>`_, and in `"Open VSX Registry" <https://open-vsx.org/extension/Slipshow/slipshow>`_.

The plugin will be activated on ``.slp`` files. It will start a preview server,
whose address is communicated through a notification, but which is often
``http://localhost:8080`` if the port is available.

It additionally provides editor features such as errors, documentation on hover,
etc. Two commands are provided to go forward and backward in the preview, from
the editor (open the command palette and start typing ``Slipshow`` to see them
listed).

A setting is available to configure if you want to set up the preview to be
updated on save, or on each file change.

Other editors
=============

As long as your editor supports editing Markdown files, and the LSP protocol,
you are good to go. Just start your LSP server with the command ``slipshow lsp``!

And please `contribute to the docs
<https://github.com/panglesd/slipshow/issues>`_ if you can improve them!
