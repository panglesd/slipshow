Themes
======

Using a theme
-------------

Themes are a recent addition to Slipshow, and as a consequence, there aren't many themes to choose from… yet!

To choose a theme, specify it in the :doc:`frontmatter <frontmatter>`. It can take the name of a builtin theme, a path to a css file, or a URL pointing to a CSS file.

Here is an example of a frontmatter using the "vanier" predefined theme:

.. code-block:: txt

   ---
   theme: vanier
   ---

To get the list of supported theme files, use the ``slipshow themes list`` command:

.. code-block:: console

   $ slipshow themes list                      # List all themes
   default
     The default theme, inspired from Beamer's Warsaw theme.
   vanier
     Another Warsaw inspired theme.
   none
     Include no theme.

Here is an example of a frontmatter specifying its theme by giving a path to a CSS file:

.. code-block:: txt

   ---
   theme: themes/my-theme.css
   ---

And finally, here is an example of a frontmatter specifying its theme by giving a URL to a CSS file (Note that the compiled file will need an internet connection in order to display the presentation):

.. code-block:: txt

   ---
   theme: https://example.org/my-theme.css
   ---

Currently, very few themes are included, but you can write your own!

Creating a theme
----------------

Creating a theme consists of writing a CSS file.

Each theme can define any CSS rule. Once Slipshow is more stable, it will provide a reliable list of classes with their meanings, that is guaranteed not to change (even if the engine changes).

Currently, the layouts may still change slightly, necessitating theme updates. However, these changes won't happen frequently, and will likely be easy to update.

Here are some classes that may be of interest for a theme writer:

- ``.slip-body`` to define the look of the content of a slip.
- ``.block`` for the blocks, which can take a ``title="…"`` parameter. Similarly for ``.theorem``, ``.lemma``, ``.definition``, ``.example``, ``.corollary``, ``.remark``.
- ``#slipshow-universe`` for styling the "universe", the element containing all of the presentation's elements.
- ``#slipshow-open-window`` for styling the background color outside of the universe.
- Titles. Make sure you don't change the system UI.

If you want to use a custom font, embed the font as a self-contained CSS file that encodes the font in a ``data`` URL. Example:

.. code-block:: css

                @font-face {
                  font-family: 'Dosis';
                  src: url(data:font/truetype;charset=utf-8;base64,AAEAAA[…]WggBEAAA=) format('truetype-variations');
                  font-weight: 500;
                }

where the ``AAEAA[…]WggBEAAA=`` string can be created with the base64 utility, for instance:

.. code-block:: console

                $ base64 -w 0 dosis-variable.ttf

Submitting a theme
------------------

If you have written a theme, thank you, and please let us know about it! I'd be happy to:

- Include a link to it in this documentation,
- Maybe, even include it as a builtin theme!

This way, I can also ping you on breaking changes to the theme API.
