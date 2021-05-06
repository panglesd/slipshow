.. _themes:

Themes
========

Using a theme
---------------------------

Just add the following line in the end of the head tag:

.. code-block:: html

    <link rel="stylesheet" type="text/css" href="<link to your style>.css">

Theme list
---------------------------

Slipshow comes with its set of themes.

* Theme ``Vanier``:

.. code-block:: html

    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/slipshow@0.0.18/dist/css/themes/vanier/vanier.css">


If you want your theme
    
Writing a theme
---------------------------

You need to define the css of at least the following attributes:

* The rule ``#universe`` for the canvas,
* The rule ``slip-slip`` for the slips,
* The rule ``slip-title`` for slip titles,
* The rule ``slip-body`` for the inside of the slips,
* The rule ``.emphasize`` for emphasized content,
* The rules ``.block``, ``.theorem``, ``.lemma``, ``.definition``, ``.example``, ``.corollary``, ``.remark``, with special rules when they have the attribute ``title`` defined,
* The rule ``.cpt-slip`` for the counter (bottom right by default),
* The rules ``.toc-slip`` and ``.toc-slip li`` for the table of content,
* The rule ``.toc-slip .before`` for the entries of the table of content already seen,
* The rule ``.toc-slip .current`` for the entry of the table of content where we are,
* The rule ``.toc-slip .after`` for the entries of the table of content to come,
* The rule ``.toc-slip .toc-function`` for the entries of the table of content that are clickable,

You can also add any additionnal rules, such as ``h1``, that are not specific to ``slipshow``.
