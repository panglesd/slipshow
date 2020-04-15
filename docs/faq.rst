.. _faq:


FAQ and ...
==========================

Frequently Asked Questions
--------------------------

.. contents:: 
   :local:


Is there a Markdown syntax for slipshow?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  No, because markdown is not well-suited for that. Indeed, it does not allows to add enought meta-information, such that all the slip attributes. This lack of meta-information is what makes it beautiful, but you cannot make presentations without extra information.

  There are many enrichment to the markdown syntax, each trying to fill a hole in the amount of "meta-information" you can give. I think that it is bad for a language to have too many slightly different variation of it. It shows its limitations: there is no better way to increase its expressivity.

  You can define a slip-enhancement to markdown, call it slipMarkdown, and a compiler from slipMarkdown to html. But slipMarkdown will lose all the benefits of Markdown. I think you should stick to HTML or maybe Pug, see :ref:`whyhtml`.
  
.. _whyhtml:

Do I really have to write plain HTML?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Many people complain about the cumbersome of writing html. However, I don't think the complaints are really justified. It is true that the html is not the less verbose, with opening and closing tags, even for inline elements.

  I think the more important thing is to use a good editor. My personnal taste is emacs, but I am sure there are tons of great editors to write html. Do not write everything by hand, but in a more "high-level" way: use shortcuts to add elements, attributes, move your cursor according to the tree an html file defines...

  If I failed to convince you, and that is certainly the majority of people, you can have a look at `pug <https://pugjs.org>`_. It is a language that can be compiled to html, using `pug-cli <https://www.npmjs.com/package/pug-cli>`_. The language has the same expressivity as html, but follows different precepts: no closing tags, the range of an element is defined using indentation. It makes it often more readable, you can find an example `here <https://github.com/pugjs/pug#syntax>`_. I plan to add a version of the tutorial in pug.
  
...
---
