This file has many problems:

  $ slipshow compile slip.md
  Error at File "slip.md", line 3, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip.md", line 13, characters 8-11:
  ID 'id1' has already been given at File "slip.md", line 7, characters 2-5.
  Error at File "slip.md", line 10, characters 2-5:
  ID 'id1' has already been given at File "slip.md", line 7, characters 2-5.

Adding a frontmatter, locations are still cool

  $ cat frontmatter slip.md > slip-with-frontmatter.md
  $ slipshow compile slip-with-frontmatter.md
  Error at File "slip-with-frontmatter.md", line 5, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip-with-frontmatter.md", line 15, characters 8-11:
  ID 'id1' has already been given at File "slip-with-frontmatter.md", line 9, characters 2-5.
  Error at File "slip-with-frontmatter.md", line 12, characters 2-5:
  ID 'id1' has already been given at File "slip-with-frontmatter.md", line 9, characters 2-5.

Testing with an include

  $ cat slip.md include > slip-with-include.md
  $ slipshow compile slip-with-include.md
  Error at File "slip-with-include.md", line 3, characters 24-33:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "subfile.md", line 1, characters 2-5:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 2-5.
  Error at File "slip-with-include.md", line 13, characters 8-11:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 2-5.
  Error at File "slip-with-include.md", line 10, characters 2-5:
  ID 'id1' has already been given at File "slip-with-include.md", line 7, characters 2-5.
