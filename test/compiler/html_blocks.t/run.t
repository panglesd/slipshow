  $ export SLIPSHOW__SECRET__NO_ENGINE=TRUE
  $ slipshow compile html_blocks.md

  $ show_source html_blocks.html | grep grep_block
  <b id="grep_block">is html</b>

  $ show_source html_blocks.html | grep grep_span
  <p><span>And </span><span as-html><blink>grep_span</blink></span><span>.</span></p>

  $ show_source html_blocks.html | grep "external_inline_grep"
  <p><span>And </span><span as-html><blink>grep_span</blink></span><span>.</span></p>

$ cp carousel.html /tmp/
