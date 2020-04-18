.. _faq:


FAQ and the rest
==========================

Frequently Asked Questions
--------------------------

.. contents:: 
   :local:


How can I send my slipshow to someone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  I have no perfect answer to this question. If you use a CDN to get the engine, you can send them the ``.html`` file, but once the download it, they will still need internet to see the slipshow, and won't be able to look at it later offline. If you use a local install, you can just pack or zip your folder and send them the whole packed folder. However, they will need to unpack or unzip the file they receive to see the slipshow, not just click on the file as with a pdf. If you have an idea on how to pack a project so that it can be easily sent and opened in every paltform, please tell me!

Is there a Markdown syntax for slipshow?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  No, because markdown is not well-suited for that. Indeed, it does not allow to add enought meta-information, such that all the slip attributes. This lack of meta-information is what makes it beautiful, but you cannot make presentations without extra information.

  There are many enrichment to the markdown syntax, each trying to fill a hole in the amount of "meta-information" you can give. I think that it is bad for a language to have too many slightly different variation of it. It shows its limitations: there is no better way to increase its expressivity.

  You can define a slip-enhancement to markdown, call it MarkSlip, and a compiler from MarkSlip to html. But MarkSlip will lose all the benefits of Markdown. I think you should stick to HTML or maybe Pug, see :ref:`whyhtml`.
  
.. _whyhtml:

Do I really have to write plain HTML?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Many people complain about the cumbersome of writing html. However, I don't think the complaints are really justified. It is true that the html is not the less verbose language, with opening and closing tags, even for inline elements.

  I think the more important thing is to use a good editor. My personnal taste is emacs, but I am sure there are tons of great editors to write html. Do not write everything by hand, but in a more "high-level" way: use shortcuts to add elements, attributes, move your cursor according to the tree an html file defines...

  You can have a look at `pug <https://pugjs.org>`_. It is a language that can be compiled to html, using `pug-cli <https://www.npmjs.com/package/pug-cli>`_. The language has the same expressivity as html, but follows different precepts: no closing tags, the range of an element is defined using indentation. It makes it often more readable, you can find an example `here <https://github.com/pugjs/pug#syntax>`_. I plan to add a version of the tutorial in pug.
  
The rest
----------

Please contribute, like, share, subscribe, use, help, live, blablabla... (I just needed a new section so that the question are not added in the table of content of the index file)

