# Extensions

## Footnotes

This is a footnote in history[^1] with mutiple references[^1]
and even [text references][^1]

 [^1]: And it can have
  lazy continuation lines and multiple paragraphs
  
  If you indent one column after the footnote label start.
  
      cb
  * list item
    ablc
  * another item
    

 This is no longer the footnote.

Can we make footnotes in footnotes[^2] ?

[^2]: This gets tricky but I guess we could have a footnote[^tricky] in
  a footnote. Also footnote[^1] in footnotes[^2] is[^3] tricky for getting
  all back references rendered correctly.
 
  [^tricky]: The foot of the footnote. But that's not going to link back[^2]
 
  Second footnote

Not the footnote

[^3]:

Not the footnote but a reference to an empty footnote[^3]

Not a footnote \[^\]

\[^\]: not a footnote.


## Strikethrough

The stroken ~~*emph*~~.

Nesting the nest ~~*emph* ~~stroke~~ *emph **emph  ~~strikeagain~~***~~

There must be no blanks after the opener and before the closer. This
is \~~ not an opener and \~~this won't open ~~that does~~.

* Here we have ~~stroken `code`~~.
* Here we have ~~nested ~~stroken~~ ok~~

## Math

The inline $\sqrt{x^2-1}$ equation.

There must be no blanks after the opener and before the closer. This
makes so you can donate \$5 or \$10 dollars here and there without problem.

There is no such think as nesting $\sqrt{x^2-1}$\+3$+3$. As usual
delimiters can be \$escaped\$ $\sqrt{16\$}$

Amazing, this is [hyperlinked math $3x^2$](https://example.org)

The HTML renderer should be careful with $a < b$ escapes.

Display math can be in `math` code blocks.

```math
\left( \sum_{k=1}^n a_k b_k \right)^2 < \Phi
```

But it can also be in $$ \left( \sum_{k=1}^n
   a_k b_k \right)^2 < \Phi $$


## List task items

* [ ] Task open
* [x] Task done
* [X] Task done
*  [✓] Task done (U+2713, CHECK MARK)
*   [✔] Task done (U+2714, HEAVY CHECK MARK)
        Indent
* Of course this can all be nested
  * [𐄂] Task done (U+10102, AEGEAN CHECK MARK)
        It will be done for sure.
        
            code block
           Not a code block
  * [x] Task done
  * [~] Task cancelled
        Paragraphy
  * [~] Task canceled 
        
            we have a code block here too.
  * \[x\]Not a task
  * \[x\] Not a task
  
* [ ] 
* [ ] a
      
          Code
         Not code
      
* [ ] 
          Code
         Not code
      

## Tables

A sample table:

| Id | Name  | Description            | Link                |
|:--:|------:|:-----------------------|--------------------:|
| 1  | OCaml | The OCaml website      | <https://ocaml.org> |
| 2  | Haskell | The Haskell website | <https://haskell.org> |
| 3 | MDN Web docs | Web dev docs | <https://developer.mozilla.org/> |
| 4 | Wikipedia | The Free Encyclopedia | <https://wikipedia.org> |

Testing these non separator pipes.

| Fancy | maybe | hu\|glu |
|-------|-------|-------|
| *a \| b* | `code |` | [bl|a] |
| not \| two cols | $\sqrt(x^2 - 1)$ |

[bl|a]: https://example.org


A table with changing labels and alignement:

 | h1  |  h2 |
 |-----|:---:|
 | 1   | 2   |
 | h3  | h4  |
 |:----|----:|
 | 3   | 4   |

A simple header less table with left and right aligned columns

 |:--|--:|
 | 1 | 2 |

The simplest table:

 | 1 | 2 |

A header only table:

| h1 | h2 |
|:--:|:--:|

Maximal number of columns all rows defines number of colums:

   | h1 | h2 | h3 |
   |:---|:--:|---:|
   |left | center | right |
   | ha\!  | four | columns | in fact |
   |||||
   ||||a|

Header less table:

  |header|less|
  |this | is |

Another quoted header less table with aligement

> |----:|----:|
> | header | less |
> | again | aligned |

This is an empty table with three columns:

 | |||

## Attributes

### Block attributes

This is a paragraph with the `my-id` is.

I have `your-id`, not mine

I have `his-id`, not mine, not yours

#### This is a title with the `.blue` class

- This is an item where `key` has value `value`.
- It is not possible to attach attributes to list items... yet

I'm a paragraph with many attributes

I have much more attribute than the previous one, since they stack

I have your id

I have a lot of class: `class1`, `class2`, `class3` and `class4`

Me too\!

But spaceships matter.

Some word



### Inline attributes

 not a block attribute, but a standalone inline attribute, as I have content in the line.

In the middle of paragraphs,  work.

Similarly, at the end, they work 

Without specified delimitations, inline attributes are either  or attached to the left-closest.

Inline attributes can refer to many including with **inline**.

Attributes can be nested: [link with](example.com), attrs [with
link](example.com), attrs within.

Attributes can be attached without squares, for instance this has an
id. This `codeblock`! This ![image](as). [Links](work). **Emphasis** and *italic1* _italic2_\!

Testing ~~strikethrough~~.

## Title with an id

Title with an id
================


### Attributes definition

We can provide [attributes][a] definition to [avoid][a] [cluttering] a [line with][a] attributes.

<!-- Unknown Cmarkit block -->
<!-- Unknown Cmarkit block -->

Attributes attached to attribute definition do nothing:

A [b][attr-attached-def] c

<!-- Unknown Cmarkit block -->

However, for link definition, they are present:

A [b][link-def-with-attrs] c

[link-def-with-attrs]: http://example.com

