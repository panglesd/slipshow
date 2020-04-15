.. _themes:

Themes
========

Using a theme
---------------------------

Just add the following line in the end of the head tag:

.. code-block:: html

    <link rel="stylesheet" type="text/css" href="<link to your style>.css">


Writing a theme
---------------------------

You need to define the css of at least the following attributes:

* The rule ``#universe`` for the canvas,
* The rule ``.slip`` for the slips,
* The rule ``.slip > .titre`` for slip titles,
* The rule ``.slip > .slip-body-container`` for the inside of the slips,
* The rule ``.emphasize`` for emphasized content,
* The rules ``.block``, ``.theorem``, ``.lemma``, ``.definition``, ``.example``, ``.corollary``, ``.remark``, with special rules when they have the attribute ``title`` defined,
* The rule ``.cpt-slip`` for the counter (bottom right by default),
* The rules ``.toc-slip`` and ``.toc-slip li`` for the table of content,
* The rule ``.toc-slip .before`` for the entries of the table of content already seen,
* The rule ``.toc-slip .current`` for the entry of the table of content where we are,
* The rule ``.toc-slip .after`` for the entries of the table of content to come,
* The rule ``.toc-slip .toc-function`` for the entries of the table of content that are clickable,
* Various rules such as ``h1`` that are not specific to ``slipshow``.
