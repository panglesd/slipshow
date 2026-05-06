We can compile the file using the slip_of_mark binary

  $ slipshow compile -o file.html file.md

  $ show_source file.html | grep "<body>" -A 13
    <body>
      <div id="slipshow-vertical-flex">
        <div id="slipshow-horizontal-flex">
          <div id="slipshow-main">
            <div id="slipshow-content">
              <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000; pointer-events: none"></svg>
              <div class="slipshow-rescaler" enter-at-unpause=~duration:0 slip>
  <div class="slip">
  <div class="slip-body">
  <div>
  <h1><span>A title</span></h1>
  <div pause></div>
  <p><span>A word </span><span id="id" emph-at-unpause step>and</span><span> some other words.</span></p>
  <div pause></div>

$ du -h file.html
184K	file.html

What happens if the file does not exists? There is an error message...

  $ slipshow compile -o file.html non-existing-file.md
  slipshow: non-existing-file.md: No such file or directory
  [123]

If we do not pass an output file, it is infer the output name from the input name

  $ cp file.md blibli.md
  $ slipshow compile blibli.md
  $ ls blibli.html
  blibli.html

If we do not pass an input file, it gets its value from stdin

  $ slipshow compile -o file.html << EOF
  > # Title
  > 
  > Paragraph
  > EOF

  $ show_source file.html | grep "<body>" -A 11
    <body>
      <div id="slipshow-vertical-flex">
        <div id="slipshow-horizontal-flex">
          <div id="slipshow-main">
            <div id="slipshow-content">
              <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000; pointer-events: none"></svg>
              <div class="slipshow-rescaler" enter-at-unpause=~duration:0 slip>
  <div class="slip">
  <div class="slip-body">
  <div>
  <h1><span>Title</span></h1>
  <p><span>Paragraph</span></p>

If we give neither the input nor the output, stdin and stdout are used:

If we do not pass an input file, it gets its value from stdin

  $ slipshow compile > stdout.html << EOF
  > # Title
  > 
  > Paragraph
  > EOF

  $ ls stdout.html
  stdout.html
