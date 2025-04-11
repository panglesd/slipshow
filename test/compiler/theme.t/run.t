Let's start with an empty file

  $ touch file.md

No theme provided or "--theme default" is the same

  $ slipshow compile file.md -o default_theme1.html
  $ slipshow compile --theme default file.md -o default_theme2.html

  $ diff -s default_theme1.html default_theme2.html
  Files default_theme1.html and default_theme2.html are identical

In those cases, the default theme is included

  $ grep ".slip-body " default_theme1.html -A 3
      <style>.slip-body {
    /* padding:60px; */
    margin-top: auto;
    margin-bottom: auto;

slipshow theme list outputs the list of themes

  $ slipshow themes
  default
    The default theme, inspired from Beamer's Warsaw theme.
  vanier
    Another Warsaw inspired theme.
  none
    Include no theme.
  $ slipshow themes list
  default
    The default theme, inspired from Beamer's Warsaw theme.
  vanier
    Another Warsaw inspired theme.
  none
    Include no theme.

You can set a builtin theme

  $ slipshow compile --theme vanier file.md -o vanier_theme.html
  $ grep "Dosis" vanier_theme.html
   font-family: 'Dosis';
  	font-family: "Dosis";
  		font-family: "Dosis";
  	font-family: "Dosis";

"--theme none" adds no theme

  $ slipshow compile --theme none file.md -o no_theme.html
  $ grep ".slip-body " no_theme.html
  [1]

"--theme <file.css>" replaces the default theme with the local file theme

  $ echo YOYO > my_theme.css

  $ slipshow compile --theme my_theme.css file.md -o local_theme.html
 No default theme included:
  $ grep ".slip-body " local_theme.html
  [1]
 But local theme included:
  $ grep YOYO -A 1 local_theme.html
      <style>YOYO
  </style>

Remote themes also replace the default theme but are included with a link:

  $ slipshow compile --theme https://example.org file.md -o remote_theme.html
  $ grep example.org remote_theme.html
      <link href="https://example.org" rel="stylesheet" />

Independently, an arbitrary number of css files can be included with "--css", without changing the theme:

  $ slipshow compile --css https://example.org file.md --css my_theme.css -o additional_css.html
  $ grep example.org additional_css.html
      <link href="https://example.org" rel="stylesheet" /><style>YOYO
  $ grep YOYO -A 1 additional_css.html
      <link href="https://example.org" rel="stylesheet" /><style>YOYO
  </style>
  $ grep ".slip-body " additional_css.html
      <style>.slip-body {
