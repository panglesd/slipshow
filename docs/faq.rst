.. _faq:

:orphan:


Frequently Asked Questions
--------------------------

.. contents:: 
   :local:


How can I send my slipshow to someone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ..
     I have no perfect answer to this question. If you use a CDN to get the engine, you can send them the ``.html`` file, but once the download it, they will still need internet to see the slipshow, and won't be able to look at it later offline. If you use a local install, you can just pack or zip your folder and send them the whole packed folder. However, they will need to unpack or unzip the file they receive to see the slipshow, not just click on the file as with a pdf. If you have an idea on how to pack a project so that it can be easily sent and opened in every paltform, please tell me!

The compiled file is a standalone html file! Just send that, no dependencies.

That is, unless you've made some special things, such as including a video. In
this case, put all dependencies in an archive.

How can I insert an image in my presentation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the markdown syntax! ``![alternative text](path_to_file)``. The supported image types are those `supported on the web <https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img#supported_image_formats>`_.

If using a local image does not work (as in the online sliphub editor), a workaround when available is to use a link to the image on the web.

How can I add math to my presentation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the markdown syntax!
To add inline formulas, use ``$`` as in Latex. To add "display" mathematics, use a block block with math language. Here is an example:

.. code-block:: markdown

   let $m$ be the mass, $E$ be the energy and $c$ be the light celerity. The we have:

   ```math
   E = mc^2
   ```

Is there a Markdown syntax for slipshow?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ..

Yes! Slipshow started just as an engine, and you had to write html by hand. But
this had some drawbacks, the biggest of which I think is that HTML is hard to
read, and not so easy to write.

For reference and fun, here is the old answer to this question:

::

     No, because markdown is not well-suited for that. Indeed, it does not allow
     to add enought meta-information, such that all the slip attributes. This
     lack of meta-information is what makes it beautiful, but you cannot make
     presentations without extra information.

     There are many enrichment to the markdown syntax, each trying to fill a
     hole in the amount of "meta-information" you can give. I think that it is
     bad for a language to have too many slightly different variation of it. It
     shows its limitations: there is no better way to increase its expressivity.

     You can define a slip-enhancement to markdown, call it MarkSlip, and a
     compiler from MarkSlip to html. But MarkSlip will lose all the benefits of
     Markdown. I think you should stick to HTML or maybe Pug.

     Do I really have to write plain HTML?
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

     Many people complain about the cumbersome of writing html. However, I don't
     think the complaints are really justified. It is true that the html is not
     the less verbose language, with opening and closing tags, even for inline
     elements.

     I think the more important thing is to use a good editor. My personnal
     taste is emacs, but I am sure there are tons of great editors to write
     html. Do not write everything by hand, but in a more "high-level" way: use
     shortcuts to add elements, attributes, move your cursor according to the
     tree an html file defines...

     You can have a look at `pug <https://pugjs.org>`_. It is a language that
     can be compiled to html, using `pug-cli
     <https://www.npmjs.com/package/pug-cli>`_. The language has the same
     expressivity as html, but follows different precepts: no closing tags, the
     range of an element is defined using indentation. It makes it often more
     readable, you can find an example `here
     <https://github.com/pugjs/pug#syntax>`_. I plan to add a version of the
     tutorial in pug.

Can I export to PDF?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Yes! Slipshow offers a ``--markdown-output`` which allows to strip any
  slipshow-specific syntax. Then, there are multiple ways to turn markdown into
  PDF: for instance, using pandoc. It is useful to send as notes, rather than
  sending the slipshow presentation!

Can I include a PDF in a presentation?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Slipshow can only include images supported on the web. You can convert your pdf image to a supported format.

Will it look the same on all screens?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Mostly yes. Browser do what they can to render exactly the same. A low resolution might make your presentation blurry, but things will be at the same place. Sometimes font differs, but I'm trying to fix this.

Can I see my presentation on a smartphone or similar device?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Slipshow offers basic gesture to trigger steps in the presentation. But this is a work in progress. PRs or ideas welcome!

Is there a speaker view?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Yes, open it with ``s`` and send notes to it with the ``speaker-note`` action.

I don't like your system, what can I do?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  There are other great HTML5 presentation system such as `reveal.js <https://revealjs.com/>`_, `impress.js <https://impress.js.org/>`_, `eagle.js <https://zulko.github.io/eaglejs-demo/#/>`_, `Flides <https://github.com/nathanael-fijalkow/Flides>`_. There are great way to write pdf based presentation such as `Beamer <https://ctan.org/pkg/beamer>`_. You can also use `Libreoffice <https://www.libreoffice.org/discover/impress/>`_ (I have never tried).


