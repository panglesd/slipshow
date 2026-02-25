We can compile the file

  $ slipshow compile slip.md
  warning[UnkownAttribute]: Non standard attribute: 'key2'
      ┌─ slip.md:6:27
    6 │  ![](img.png){#id2 .class2 key2=value2}
      │                            ^^^^ 
  
  warning[UnkownAttribute]: Non standard attribute: 'key'
      ┌─ slip.md:3:13
    3 │  {#id .class key=value}
      │              ^^^ 
  
  warning[FSError]: file 'img.png' could not be read: img.png: No such file or directory
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
