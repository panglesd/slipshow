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
      ┌─ slip-with-include.md:4:3
    1 │  {#id1}
      │    ^^^ 
      ·  
    4 │  {#id1}
      │    ^^^ 
  
