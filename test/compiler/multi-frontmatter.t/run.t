Compatible multiple options are not reported (dimension, css files).
Incompatible options are reported (math-mode)

  $ export SLIPSHOW__SECRET__NO_ENGINE=TRUE
  $ slipshow compile main.md
  warning: file 'other-other-file.css' could not be read: other-other-file.css: No such file or directory
      ┌─ main.md:3:34
    3 │  css:   file.css other-file.css   other-other-file.css
      │                                   ^^^^^^^^^^^^^^^^^^^^ 
  
  warning: file 'other-file.css' could not be read: other-file.css: No such file or directory
      ┌─ main.md:3:17
    3 │  css:   file.css other-file.css   other-other-file.css
      │                  ^^^^^^^^^^^^^^ 
  
  warning: file 'file2.css' could not be read: file2.css: No such file or directory
      ┌─ chapter1.md:3:6
    3 │  css: file2.css
      │       ^^^^^^^^^ 
  
  warning: file 'file.css' could not be read: file.css: No such file or directory
      ┌─ main.md:3:8
    3 │  css:   file.css other-file.css   other-other-file.css
      │         ^^^^^^^^ 
  
  warning: Option 'math-mode' is assigned multiple times in incompatible ways
      ┌─ chapter1.md:4:12
    4 │  math-mode: katex
      │             ^^^^^ 
      ┌─ main.md:4:12
    4 │  math-mode: mathjax
      │             ^^^^^^^ 
  

Css files are well combined

  $ show_source main.html | grep "rel=\"stylesheet\""
  <link href="file.css" rel="stylesheet" /><link href="other-file.css" rel="stylesheet" /><link href="other-other-file.css" rel="stylesheet" /><link href="file2.css" rel="stylesheet" />

Warnings are also raised in case of duplicated fields in the same file

  $ slipshow compile single-file.md
  warning: Option 'math-mode' is assigned multiple times in incompatible ways
      ┌─ single-file.md:6:12
    5 │  math-mode: katex
      │             ^^^^^ 
    6 │  math-mode: mathjax
      │             ^^^^^^^ 
  
  warning: Option 'dimension' is assigned multiple times in incompatible ways
      ┌─ single-file.md:4:12
    3 │  dimension: 16:9
      │             ^^^^ 
    4 │  dimension: 4:3
      │             ^^^ 
  
