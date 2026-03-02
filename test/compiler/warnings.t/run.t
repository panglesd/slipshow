This file has many problems:

  $ slipshow compile slip.md
  warning[FSError]: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip.md:3:25
    3 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning[DupID]: ID id1 is assigned multiple times
      ┌─ slip.md:10:9
    7 │  Hello1{#id1}
      │          ^^^ 
    8 │  Hello2{#id1}
      │          ^^^ 
    9 │  
   10 │  Hello3{#id1}
      │          ^^^ 
  

Adding a frontmatter, locations are still cool

  $ cat frontmatter slip.md > slip-with-frontmatter.md
  $ slipshow compile slip-with-frontmatter.md
  warning[FSError]: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip-with-frontmatter.md:5:25
    5 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-frontmatter.md:12:9
    9 │  Hello1{#id1}
      │          ^^^ 
   10 │  Hello2{#id1}
      │          ^^^ 
   11 │  
   12 │  Hello3{#id1}
      │          ^^^ 
  

Testing with an include

  $ cat slip.md include > slip-with-include.md
  $ slipshow compile slip-with-include.md
  warning[FSError]: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip-with-include.md:3:25
    3 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-include.md:10:9
    7 │  Hello1{#id1}
      │          ^^^ 
    8 │  Hello2{#id1}
      │          ^^^ 
    9 │  
   10 │  Hello3{#id1}
      │          ^^^ 
      ┌─ subfile.md:4:3
    1 │  {#id1}
      │    ^^^ 
      ·  
    4 │  {#id1}
      │    ^^^ 
  

  $ slipshow compile all.md
  warning[Frontmatter]: Error while parsing frontmatter field 'dimension'
      ┌─ all.md:4:11
    4 │  dimension: 16:16
      │            ^^^^^^ Expected "4:3", "16:9", or two integers separated by a 'x'
  
  warning[Frontmatter]: Frontmatter field 'unknown-frontmatter' is not interpreted by slipshow
      ┌─ all.md:3:1
    3 │  unknown-frontmatter: field
      │  ^^^^^^^^^^^^^^^^^^^ 
      = Recognized fields are: 'dimension', 'toplevel-attributes', 'math-link', 'theme', 'css', 'js', 'highlightjs-theme', 'math-mode', 'external-ids'
  
  warning[ActionParsing]: Failed to parse
      ┌─ all.md:41:16
   41 │  {up="~margin:2 ~margin:3"}
      │                 ^^^^^^^ Named argument 'margin' is duplicated. This instance is ignored.
  
  warning[ActionParsing]: Failed to parse
      ┌─ all.md:35:11
   35 │  {up="uid1 uid2"}
      │            ^^^^ Action up does not support multiple arguments
  
  warning[ActionParsing]: Failed to parse
      ┌─ all.md:33:11
   33 │  {unfocus="something"}
      │            ^^^^^^^^^ The unfocus action does not accept any argument
  
  warning[ActionParsing]: Action up arguments could not be parsed
      ┌─ all.md:31:6
   31 │  {up="~:12"}
      │       ^^^^ '~' needs to be followed by a name
  
  warning[ActionParsing]: Failed to parse
      ┌─ all.md:29:32
   29 │  {up="~duratiooon:12  ~duration:aaa"}
      │                                 ^^^ Error during float parsing
  
  warning[ActionParsing]: 
      ┌─ all.md:29:6
   29 │  {up="~duratiooon:12  ~duration:aaa"}
      │       ^^^^^^^^^^^ Action 'up' does not take argument 'duratiooon'
      = 'up' accepts arguments 'duration', 'margin'
  
  warning[UnknownAttribute]: Non standard attribute: 'unknown-attribute'
      ┌─ all.md:18:2
   18 │  {unknown-attribute}
      │   ^^^^^^^^^^^^^^^^^ 
  
  warning[IDNotFound]: No element with id 'missing-id' was found
      ┌─ all.md:16:8
   16 │  {pause=missing-id}
      │         ^^^^^^^^^^ This should be an ID present in the document
  
  warning[WrongType]: Wrong type
      ┌─ all.md:14:1
   14 │  This is not a carousel
      │  ^^^^^^^^^^^^^^^^^^^^^^
      │  │
      │  This expects the id of a carousel or pdf
      │  This is not a carousel or pdf
  
  warning[WrongType]: Wrong type
      ┌─ all.md:11:1
   11 │  Hello
      │  ^^^^^
      │  │
      │  This expects the id of a slip-script
      │  This is not a slip-script
  
  warning[UnknownAttribute]: Non standard attribute: 'dqzd'
  
  warning[IDNotFound]: No element with id 'yo' was found
  
  warning[FSError]: file 'missing.md' could not be read: missing.md: No such file or directory
      ┌─ all.md:8:4
    8 │  ![](missing.md)
      │     ^^^^^^^^^^^^ 
  
  warning[DupID]: ID duplicated-id is assigned multiple times
      ┌─ all.md:22:3
    7 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
      ·  
   20 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
   21 │  
   22 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
  
  warning[ChildrenAttrs]: Children classes cannot have a value
      ┌─ all.md:24:19
   24 │  {children:.class="have value"}
      │                    ^^^^^^^^^^ 
  
