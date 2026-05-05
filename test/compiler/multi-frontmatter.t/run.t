Compatible multiple options are not reported (dimension, css files).
Incompatible options are reported (math-mode)

  $ slipshow compile main.md
  warning: Option 'math-mode' is assigned multiple times in incompatible ways
      ┌─ chapter1.md:4:11
    4 │  math-mode: katex
      │            ^^^^^^ 
      ┌─ main.md:4:11
    4 │  math-mode: mathjax
      │            ^^^^^^^^ 
  
  warning: file 'file2.css' could not be read: file2.css: No such file or directory
  
  warning: file 'file.css' could not be read: file.css: No such file or directory
  

Css files are well combined

  $ show_source main.html | grep "rel=\"stylesheet\""
  <link href="file.css" rel="stylesheet" /><link href="file2.css" rel="stylesheet" />
