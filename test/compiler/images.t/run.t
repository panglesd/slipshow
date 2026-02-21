We can compile the file

  $ slipshow compile slip.md
  error[FSError]: file 'img.png' could not be read: img.png: No such file or directory
      ┌─ slip.md:6:4
    1 │  A paragraph with an ![image](img.png)
      │                              ^^^^^^^^^ 
      ·  
    4 │  ![](img.png)
      │     ^^^^^^^^^ 
    5 │  
    6 │  ![](img.png){#id2 .class2 key2=value2}
      │     ^^^^^^^^^ 

  $ show_source slip.html | grep "<slip-body>" -A 10
  [1]

What is the purpose of all this?
