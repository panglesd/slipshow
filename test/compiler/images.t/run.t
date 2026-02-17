We can compile the file

  $ slipshow compile slip.md
  Error at File "slip.md", line 5, characters 28-37:
  Missing file: img.png (img.png: No such file or directory). Considering it as an URL.
  Error at File "slip.md", line 8, characters 3-12:
  Missing file: img.png (img.png: No such file or directory). Considering it as an URL.
  Error at File "slip.md", line 11, characters 3-12:
  Missing file: img.png (img.png: No such file or directory). Considering it as an URL.

  $ show_source slip.html | grep "<slip-body>" -A 10
  [1]

What is the purpose of all this?
