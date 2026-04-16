This file has many problems:

  $ slipshow compile slip.md
  warning: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip.md:3:25
    3 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning: ID id1 is assigned multiple times
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
  warning: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip-with-frontmatter.md:5:25
    5 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning: ID id1 is assigned multiple times
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
  warning: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip-with-include.md:3:25
    3 │  A missing file: ![image](img.png)
      │                          ^^^^^^^^^ 
  
  warning: ID id1 is assigned multiple times
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
  warning: Error while parsing frontmatter field 'dimension'
      ┌─ all.md:4:11
    4 │  dimension: 16:16
      │            ^^^^^^ Expected "4:3", "16:9", or two integers separated by a 'x'
  
  warning: Frontmatter field 'unknown-frontmatter' is not interpreted by slipshow
      ┌─ all.md:3:1
    3 │  unknown-frontmatter: field
      │  ^^^^^^^^^^^^^^^^^^^ 
      = Recognized fields are: 'dimension', 'toplevel-attributes', 'math-link', 'theme', 'css', 'js', 'highlightjs-theme', 'math-mode', 'external-ids'
  
  warning: Invalid frontmatter entry
      ┌─ all.md:7:1
    7 │  anothe rwrong line
      │  ^^^^^^^^^^^^^^^^^^ 
      = Frontmatter have to be of the form "key:value" on a single line.
  
  warning: Invalid frontmatter entry
      ┌─ all.md:5:1
    5 │  wrong line
      │  ^^^^^^^^^^ 
      = Frontmatter have to be of the form "key:value" on a single line.
  
  warning: Failed to parse
      ┌─ all.md:44:16
   44 │  {up="~margin:2 ~margin:3"}
      │                 ^^^^^^^ Named argument 'margin' is duplicated. This instance is ignored.
  
  warning: Failed to parse
      ┌─ all.md:38:11
   38 │  {up="uid1 uid2"}
      │            ^^^^ Action up does not support multiple arguments
  
  warning: Failed to parse
      ┌─ all.md:36:11
   36 │  {unfocus="something"}
      │            ^^^^^^^^^ The unfocus action does not accept any argument
  
  warning: Action up arguments could not be parsed
      ┌─ all.md:34:6
   34 │  {up="~:12"}
      │       ^^^^ '~' needs to be followed by a name
  
  warning: Failed to parse
      ┌─ all.md:32:32
   32 │  {up="~duratiooon:12  ~duration:aaa"}
      │                                 ^^^ Error during float parsing
  
  warning: Invalid action argument
      ┌─ all.md:32:6
   32 │  {up="~duratiooon:12  ~duration:aaa"}
      │       ^^^^^^^^^^^ Action 'up' does not take argument 'duratiooon'
      = 'up' accepts arguments 'duration', 'margin'
  
  warning: Non standard attribute: 'unknown-attribute'
      ┌─ all.md:21:2
   21 │  {unknown-attribute}
      │   ^^^^^^^^^^^^^^^^^ 
  
  warning: No element with id 'missing-id' was found
      ┌─ all.md:19:8
   19 │  {pause=missing-id}
      │         ^^^^^^^^^^ This should be an ID present in the document
  
  warning: Wrong type
      ┌─ all.md:17:1
   17 │  This is not a carousel
      │  ^^^^^^^^^^^^^^^^^^^^^^
      │  │
      │  This expects the id of a carousel or pdf
      │  This is not a carousel or pdf
  
  warning: Wrong type
      ┌─ all.md:14:1
   14 │  Hello
      │  ^^^^^
      │  │
      │  This expects the id of a slip-script
      │  This is not a slip-script
  
  warning: No element with id 'yo' was found
      ┌─ all.md:2:27
    2 │  toplevel-attributes: exec=yo dqzd
      │                            ^^ This should be an ID present in the document
  
  warning: Non standard attribute: 'dqzd'
      ┌─ all.md:2:30
    2 │  toplevel-attributes: exec=yo dqzd
      │                               ^^^^ 
  
  warning: file 'missing.md' could not be read: missing.md: No such file or directory
      ┌─ all.md:11:4
   11 │  ![](missing.md)
      │     ^^^^^^^^^^^^ 
  
  warning: ID duplicated-id is assigned multiple times
      ┌─ all.md:25:3
   10 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
      ·  
   23 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
   24 │  
   25 │  {#duplicated-id}
      │    ^^^^^^^^^^^^^ 
  
  warning: Children classes cannot have a value
      ┌─ all.md:27:19
   27 │  {children:.class="have value"}
      │                    ^^^^^^^^^^ 
  
