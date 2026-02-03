===========
Mathematics
===========

Writing mathematics
===================

You have two modes for writing mathematics: inline and block (also called
"display"). Inline math is the small formulas you include in a sentence, inside
the flow of text. Blocks are optentially bigger formulas that break the flow of
text.

In order to write inline math, enclose it between ``$``. For instance: ``The
irrational $\sqrt 2$ is the positive number that equals $2$ when squared.

In order to write display math, either enclose it between ``$$``, or put it inside a ``math`` code block

.. code-block:: markdown

   The formula $$\sum \vec F = m\vec a$$ is from Newton. When applied to free fall, we get:

   ``` math
   m\vec g = m\vec a
   ```

The syntax for mathematics is the same as the one for LaTeX math mode.

The math renderer: MathJax
==========================

Slipshow uses a third-party renderer to render mathematics. The rendering
happens currently when you load your presentation (as opposed to when you
compile it). The renderer is `MathJax <https://www.mathjax.org/>`_, version
3.2.2. It is included in the html file, as soon as you are using mathematics, so
the html file is still completely standalone, and you don't need anything
installed locally to have it work.

Configure your renderer
=======================

You can add configure the renderer simply by setting a value anywhere in your
document. This allows, for instance, to define macros, or decide which
extensions are loaded.

.. code-block::

   <style>
   window.MathJax = {
     tex: {
       macros: { RR: '{\\mathbb R}' }
     }
   };
   </script>

The `list of options <https://docs.mathjax.org/en/v3.2/options/index.html>`_ can
be found on `MathJax's docs <https://docs.mathjax.org/en/v3.2/>`_. The default
value used by Slipshow is:

.. code-block::

   window.MathJax = {
     loader: {load: ['[tex]/html']},
     tex: {packages: {'[+]': ['html']}}
   };

Reveal content bit by bit
=========================

MathJax, when loaded with the html extension (which is the case by default in
Slipshow) allows to assign classes and identifiers to the HTML elements.
One can use ``\cssId{id-name}{math}`` and ``\class{class-name}{math}`` to
respectively assign an identifier, and a class.

This allows to easily make them target of actions. For instance, one can use the ``pause`` action with a target to reveal content bit by bit. The ``reveal`` action and ``unrevealed`` class are also useful.

.. slipshow-example::
   :visible: both
   :dimension: 4:3

   # Some title to make it more realistic

   ```math
   \begin{array}{rcrcrcrcr}
    S  &=&   1 &+&   2 &+& \dots &+& 100 \\
   \cssId{pause1}{+} \quad S  &=& 100 &+&  99 &+& \dots &+&   1 \cssId{pause2}{} \\
   \hline
   2S  &=& 101 &+& 101 &+& \dots &+& 101
   \end{array}
   ```

   {pause=pause1 unreveal=pause1}

   {reveal=pause1}

   {pause=pause2}

Alternative renderer: KaTeX
===========================

You can chose to use an alternate renderer: `KaTeX <https://katex.org/>`_,
version 0.16.28. Unless you have a specific requirement, you have no reason to
do this.

The reason I include two renderers is that the latest version of MathJax is 4.x,
while the one used by Slipshow is 3.x, and I have technical issues when trying
to upgrade from version 3 to version 4 (see this `post
<https://groups.google.com/g/mathjax-users/c/ux3EJK9H4-U>`_). The latest version
of KaTeX can be included, but its integration in Slipshow is less mature.

In order to chose between the two renderers, use the ``math-mode`` frontmatter
field with either the ``mathjax`` or ``katex`` value. Or alternatively, the
``--math-mode`` cli flag with the same values.

In order to configure KaTeX, you also just define an object:

.. code-block::

   <style>
   window.Katex = {
     macros: {"\\RR": "\\mathbb{R}"}
   };
   </style>

whose default value is:

.. code-block::

   window.Katex = {
     delimiters: [
       {left: '\\(', right: '\\)', display: false},
       {left: '\\[', right: '\\]', display: true}
     ],
     throwOnError : false,
     strict: false,
     trust:true
   };

In order to give a class or an id, use ``htmlClass{class}{math}`` and
``htmlId{id}{math}``. However, from personal but shallow testing, KaTeX does not
always preserve the order of elements from source to math, so the ``pause``
action might work less well. Other actions, such that ``reveal``, should work
well.
