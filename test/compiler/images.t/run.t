We can compile the file

  $ slipshow compile slip.md
  Error at File "slip.md", line 1, characters 28-37:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip.md", line 4, characters 3-12:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)
  Error at File "slip.md", line 6, characters 3-12:
  Missing file: img.png, considering it as an URL. (img.png: No such file or directory)

  $ show_source slip.html | grep "<slip-body>" -A 10
  [1]

What is the purpose of all this?
