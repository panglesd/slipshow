We can compile the file using the slip_of_mark binary

  $ slipshow compile -o file.html file.md

  $ cat file.html | grep "<body>" -A 10
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler" slipshow-entry-point>
  <div class="slip">
  <div class="slip-body">
  <h1 id="a-title"><a class="anchor" aria-hidden="true" href="#a-title"></a><span>A title</span></h1>
  <div pause></div>
  <p><span>A word </span><span id="id" step emph-at-unpause>and</span><span> some other words.</span></p>
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

  $ cat file.html | grep "<body>" -A 10
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler" slipshow-entry-point>
  <div class="slip">
  <div class="slip-body">
  <h1 id="title"><a class="anchor" aria-hidden="true" href="#title"></a><span>Title</span></h1>
  <p><span>Paragraph</span></p>
  </div>
  </div>

If we give neither the input nor the output, stdin and stdout are used:

If we do not pass an input file, it gets its value from stdin

  $ slipshow compile > stdout.html << EOF
  > # Title
  > 
  > Paragraph
  > EOF

  $ ls stdout.html
  stdout.html

If we pass a mathjax value, with a remote url:

  $ echo "#title \$1+1=0\$" > with_inline_math.md
  $ cat > with_block_math.md << EOF
  > \`\`\`math
  > 1 + 1 = 0
  > \`\`\`
  > EOF
  $ echo "#title 1+1=0" > without_math.md

  $ slipshow compile -o m1.html --mathjax https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js with_inline_math.md
  $ slipshow compile -o m2.html --mathjax https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js with_block_math.md
  $ slipshow compile -o m3.html --mathjax https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js without_math.md

  $ cat m1.html | grep mathjax
  <script id="MathJax-script" src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
  $ cat m2.html | grep mathjax
  <script id="MathJax-script" src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
  $ cat m3.html | grep mathjax
  [1]

With a file

  $ echo "dummyABC" > mathjax.js
  $ slipshow compile -o m.html --mathjax mathjax-unknown.js with_inline_math.md
  slipshow: [WARNING] Could not read file: mathjax-unknown.js. Considering it as an URL. (mathjax-unknown.js: No such file or directory)
  $ slipshow compile -o m.html --mathjax mathjax.js with_inline_math.md
  $ cat m.html | grep -A 1 dummyABC
  <script id="MathJax-script">dummyABC
  </script>

Images

  $ slipshow compile file_with_image.md
  $ cat file_with_image.html | grep "alt=\"image\"" | grep base64
  <p><span>A paragraph with an </span><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAABg2lDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaIVB4OIOGSoTnZREcdahSJUCLVCqw4ml35Bk4YkxcVRcC04+LFYdXBx1tXBVRAEP0BcXZwUXaTE/yWFFjEeHPfj3b3H3Tsg2KgwzeqKA5pum+lkQszmVsXwK/ogIIIhCDKzjDlJSsF3fN0jwNe7GM/yP/fn6FfzFgMCInGcGaZNvEE8s2kbnPeJBVaSVeJz4gmTLkj8yHXF4zfORZeDPFMwM+l5YoFYLHaw0sGsZGrE08RRVdMpP5j1WOW8xVmr1FjrnvyFkby+ssx1mqNIYhFLkCBCQQ1lVGAjRqtOioU07Sd8/COuXyKXQq4yGDkWUIUG2fWD/8Hvbq3C1KSXFEkA3S+O8zEGhHeBZt1xvo8dp3kChJ6BK73trzaA2U/S620tegQMbAMX121N2QMud4DhJ0M2ZVcK0QwWCsD7GX1TDhi8BXrXvN5a+zh9ADLUVeoGODgExouUve7z7p7O3v490+rvB2/RcqXOpP/kAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAB3RJTUUH5wsUDBghqFYBIAAAABl0RVh0Q29tbWVudABDcmVhdGVkIHdpdGggR0lNUFeBDhcAAACeSURBVBjTbY4xCoQwFEQny1aWCVFPkEKTK4SAeATv5wE8gjew+wpewV/aB9xC1Cz4qhkeDIPjYhzHruuGYTgScCciUkp571P9wYVzLsYopUTCd55nAHmen31dV2YuigIAM6OqKmPM6YQQAO4KQEzTtO87AGttWZZZlvV9T0QhhKZpnmvbthlj6rp+v/bKo5dlYea2bf98Oq61JqJ0/AfIKIeErZAqOwAAAABJRU5ErkJggg==" alt="image" ></p>
