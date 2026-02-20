This file has many problems:

  $ slipshow compile slip.md
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip.md:10:9
    7 │  Hello1{#id1}
      │          ^^^ 
      ·  
   10 │  Hello3{#id1}
      │          ^^^ 
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip.md:8:9
    7 │  Hello1{#id1}
      │          ^^^ 
    8 │  Hello2{#id1}
      │          ^^^ 
  Error at File "slip.md", line 3, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip.md", line 10, characters 8-11:
  ID 'id1' has already been given at File "slip.md", line 7, characters 8-11.
  Error at File "slip.md", line 8, characters 8-11:
  ID 'id1' has already been given at File "slip.md", line 7, characters 8-11.

Adding a frontmatter, locations are still cool

  $ cat frontmatter slip.md > slip-with-frontmatter.md
  $ slipshow compile slip-with-frontmatter.md
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-frontmatter.md:12:9
    9 │  Hello1{#id1}
      │          ^^^ 
      ·  
   12 │  Hello3{#id1}
      │          ^^^ 
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-frontmatter.md:10:9
    9 │  Hello1{#id1}
      │          ^^^ 
   10 │  Hello2{#id1}
      │          ^^^ 
  Error at File "slip-with-frontmatter.md", line 5, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip-with-frontmatter.md", line 12, characters 8-11:
  ID 'id1' has already been given at File "slip-with-frontmatter.md", line 9, characters 8-11.
  Error at File "slip-with-frontmatter.md", line 10, characters 8-11:
  ID 'id1' has already been given at File "slip-with-frontmatter.md", line 9, characters 8-11.

Testing with an include

  $ cat slip.md include > slip-with-include.md
  $ slipshow compile slip-with-include.md
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-include.md:7:9
    7 │  Hello1{#id1}
      │          ^^^ 
      ┌─ slip-with-include.md:4:3
    4 │  {#id1}
      │    ^^^ 
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-include.md:7:9
    7 │  Hello1{#id1}
      │          ^^^ 
      ┌─ slip-with-include.md:1:3
    1 │  {#id1}
      │    ^^^ 
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-include.md:10:9
    7 │  Hello1{#id1}
      │          ^^^ 
      ·  
   10 │  Hello3{#id1}
      │          ^^^ 
  error[DupID]: ID id1 is assigned multiple times
      ┌─ slip-with-include.md:8:9
    7 │  Hello1{#id1}
      │          ^^^ 
    8 │  Hello2{#id1}
      │          ^^^ 
  Error at File "slip-with-include.md", line 3, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "subfile.md", line 4, characters 2-5:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 8-11.
  Error at File "subfile.md", line 1, characters 2-5:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 8-11.
  Error at File "slip-with-include.md", line 10, characters 8-11:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 8-11.
  Error at File "slip-with-include.md", line 8, characters 8-11:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 8-11.
