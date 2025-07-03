Let's start with an empty file

  $ touch file.md

We can provide the dimension with --dimension

  $ slipshow compile --dimension qfdesfesf file.md
  slipshow: option '--dimension': Expected "4:3", "16:9", or two integers
            separated by a 'x'
  Usage: slipshow compile [OPTION]… [FILE.md]
  Try 'slipshow compile --help' or 'slipshow --help' for more information.
  [124]
  $ slipshow compile --dimension wrongxefzefezf file.md
  slipshow: option '--dimension': invalid value 'wrong', expected an integer
  Usage: slipshow compile [OPTION]… [FILE.md]
  Try 'slipshow compile --help' or 'slipshow --help' for more information.
  [124]
  $ slipshow compile --dimension 1920xwrong file.md
  slipshow: option '--dimension': invalid value 'wrong', expected an integer
  Usage: slipshow compile [OPTION]… [FILE.md]
  Try 'slipshow compile --help' or 'slipshow --help' for more information.
  [124]
  $ slipshow compile --dimension 16:9 file.md
  $ slipshow compile --dimension 4:3 file.md
  $ slipshow compile --dimension 1920x1080 file.md

-d and --dim work too

  $ slipshow compile --dim 16:9 file.md
  $ slipshow compile -d 16:9 file.md
