.. _recipes:

Slipshow recipes and tools
==============================

In this part of the documentation are showcased different tricks or way to use slipshow.

.. contents:: Table of contents
   :local:

Including your tikz figures
---------------------------

If you are coming from latex, you might have many figures already written in tikz, that you don't want to do again using another tool. Or, you might just want to keep doing your figures in tikz.

There is a way to include your figures from tikz to slipshow: compile your figures with pdflatex, convert them into svg, and include them in you slipshow presentation. Slipshow provides a script to do this automatically, but the second section explains how to do it "by hand". Note that the script works only for linux.

Using the slipshow built-in tools (linux only)
*************************************************

If you want to use the scripts in slipshow, you need not to use the CDN provided version, but rather install it using npm or from the archive, see :ref:`getting-started`. Make sure you have a ``package.json`` file in the root folder of your presentation, otherwise type ``npm init`` to create this file. This allows the script to know where the root of the presentation is.

The figures will be stored in he ``figures`` directory, at the root of the project. Each figure will have its own subdirectory. To create a new figure, named for instance ``fig-1``, run:

.. code-block:: bash

   $ npx new-figure

This script will ask you the name of the new figure, and then create the necessary subdirectories and files. In particular, a file in ``figures/awesome-figure/awesome-figure.tex`` has the minimal content to be a tikz figure, waiting for you to complete it. In particular, you can use the beamer overlays to generate multiple figures. In this case, you might need to tell pdflatex how many overlays there are, by enclosing the whole picture into ``\only<1-N>{ ... }`` where ``N`` is the number of overlays.

Now that you have written your figure, you need to compile it. To do so, run:

.. code-block:: bash

   $ npx compile-figure fig-1

or

.. code-block:: bash

   $ npx compile-figure --all

This will create a bunch of ``svg`` files, called ``fig-1_1.svg``, ``fig-1_2.svg``, ... corresponding to the different overlays of your figure.

Lastly, you need to include your figures in your presentation. To do so, add the following html tag:

.. code-block:: html

	<div style="text-align: center" pause>
	    <img static-at="-2" src="figures/fig-1/fig-1_1.svg"/>
	    <img static-at="0 2 -3" src="figures/fig-1/fig-1_2.svg"/>
	    <img static-at="0 3 -4" src="figures/fig-1/fig-1_3.svg"/>
	    <img static-at="0 4" src="figures/fig-1/fig-1_4.svg"/>
	</div>

Of course, you need to adjust the values of the parameter ``static-at`` to suit you needs (the doc on :ref:`static-at`). I might add a dedicated tag called ``slip-tikz`` to make it less verbose someday...


By hand
*********************************

Here is what the scripts do, in case you want to have more control, and execute the commands yourself. First, just create in the right directory a file containing:

.. code-block:: latex

		\documentclass[beamer]{standalone}
		\usepackage{tikz}
		\usetikzlibrary{external}
		\tikzexternalize % activate! 
		\begin{document}
		\begin{standaloneframe}
		
		% If overlays do not work, use \only<1-n>{...} where n is the max overlay
		% \only<1-1000>{
		  \begin{tikzpicture}[]
			% ...   
		  \end{tikzpicture}
		% }
		\end{standaloneframe}
		\end{document}


Write your tikz figure in a file like this. Once it is done, to compile, use

.. code-block:: bash

		$ pdflatex -shell-escape

Indeed, in order for the figures to be compiled in separate files by ``tikzexternalize``, you need the argument ``-shell-escape`` to be given. If you are using windows, please tell me whether this works or not!

Running this command will create several files containing the different overlays of the figure (only one file if it has no overlay). If your tex file is called ``name.tex``, they are named ``name-figure0.pdf``, ``name-figure1.pdf``, ... However, html cannot read pdf out of the box, so you need to convert them into ``svg`` files, for instance using the ``pdf2svg`` utility (windows users... sorry I don't know. Maybe `here <https://github.com/jalios/pdf2svg-windows>`_?)

The last step, is to include your files inside your presentation, such as with:

.. code-block:: html

	<div style="text-align: center" pause>
	    <img static-at="-2" src="figures/fig-1/fig-1_1.svg"/>
	    <img static-at="0 2 -3" src="figures/fig-1/fig-1_2.svg"/>
	    <img static-at="0 3 -4" src="figures/fig-1/fig-1_3.svg"/>
	    <img static-at="0 4" src="figures/fig-1/fig-1_4.svg"/>
	</div>

