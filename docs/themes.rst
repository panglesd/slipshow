Themes
======

Using a theme
-------------

Theme support is pretty recent in Slipshow. As a consequence, there aren't many themes to choose from... yet!

To choose a theme, specify it in the frontmatter. It can take the name of a builtin theme, a path to a css file, or a URL pointing to a CSS file.

Here is an example of a frontmatter to using the "vanier" predefined theme:

.. code-block:: console

   ---
   theme: default
   ---

To get the list of supported theme files, use ``slipshow themes list``:

.. code-block:: console

   $ slipshow themes list                      # List all themes
   default
     The default theme, inspired from Beamer's Warsaw theme.
   vanier
     Another Warsaw inspired theme.
   none
     Include no theme.

Here is an example of a frontmatter specifying its theme by giving a path to a css file:

.. code-block:: console

   ---
   theme: themes/my-theme.css
   ---

And finally, here is an example of a frontmatter specifying its theme by giving an url to the css file (Note that the compiled file will need internet connection in order to display the presentation):

.. code-block:: console

   ---
   theme: https://example.org/my-theme.css
   ---

Currently, very few themes are included. However, you can write your own theme!

Creating a theme
----------------

Creating a theme consists in writing a CSS file.

Each theme can define any CSS rule. Once Slipshow is more stable, it will provide a list of classes with their meaning, that is guaranteed not to change (even if the engine change).

Currently, the layouts may still slightly change, necessitating updates in the themes. However, these changes won't happen frequently, and will likely be easy to update!

Here are some classes that may be of interest for a theme writer:

- ``.slip-body`` to define the look of the content of a slip.
- ``.block`` for the blocks, which can take a ``title="..."`` parameter. Similarly for ``.theorem``, ``.lemma``, ``.definition``, ``.example``, ``.corollary``, ``.remark``.
- ``#slipshow-universe`` for styling the "universe", the element containing all of the presentation's elements.
- ``#slipshow-open-window`` for styling the background color outside of the universe.
- Titles. Make sure not to change the system UI.

If you want to change the font, make sure to have a self-contained css file, by using data URLs to embed the font in the CSS file. Example:


.. code-block:: css

                @font-face {
                  font-family: 'Dosis';
                  src: url(data:font/truetype;charset=utf-8;base64,AAEAAA[...]WggBEAAA=) format('truetype-variations');
                  font-weight: 500;
                }

where the ``AAEAA[...]WggBEAAA=`` string can be found with the base64 utility, for instance:

.. code-block:: console

                $ base64 -w 0 dosis-variable.ttf

Submitting a theme
------------------

If you have written a theme, thank you! I'm happy to:

- Include a link to it in this documentation,
- Maybe, even include it as a builtin theme!

This way, I can also ping you on breaking changes.
