Trying directory output

  $ touch f.md
  $ slipshow compile --output dist/ f.md
  slipshow: Sys_error("dist/: No such file or directory")
  [123]

  $ mkdir dist/
  $ slipshow compile --output dist f.md
  slipshow: Sys_error("dist: Is a directory")
  [123]

  $ slipshow compile --output dist/ f.md

Trying a UX for slipshow server mode

  $ slipshow compile --web-mode <path1> <options> file.md
  ***** UNREACHABLE *****

I guess slipshow serve has the same?

  $ slipshow serve --web-mode <path1> <options> file.md
  ***** UNREACHABLE *****

And there is a way to output the assets

  $ slipshow web-assets <path2>
  ***** UNREACHABLE *****

Questions:

- Is the name --web-mode good? What about --server-mode? It conflicts/confuses with serve subcommand somehow?
- What about the path1? Should it be relative? What about path2? Should it be relative?

Probably:
- <path1> is taken relatively from the path to file.md.
- <path2> is taken relatively from the command.
- --web-mode is fine

So for instance:

  $ slipshow compile --web-mode assets/ -o root/ src/file.md
  ***** UNREACHABLE *****
  $ slipshow web-assets root/assets/
  ***** UNREACHABLE *****

What about managing everything under a web root?

  $ slipshow compile --web-mode root/ --assets assets/ -o pres1/ file.md
  ***** UNREACHABLE *****
  $ slipshow web-assets --web-mode root/ assets/
  ***** UNREACHABLE *****

Where the end hierarchy is:

  $ tree root/
  root/
  root/pres1/file.html
  root/assets/...

What about the assets such as images etc? For instance `![](img/a.png)`?

- They are copied under the webroot. For instance in the example above:

  $ tree root/
  root/
  root/pres1/file.html
  root/pres/img/a.png
  root/assets/...


Interesting, I think I like that better.

Not sure if it is helpful for examples.slipshow.org though
