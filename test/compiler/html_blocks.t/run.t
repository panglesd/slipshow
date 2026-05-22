  $ export SLIPSHOW__SECRET__NO_ENGINE=TRUE
  $ slipshow compile html_blocks.md

  $ show_source html_blocks.html | grep grep_block
  <b id="grep_block">is html</b>

  $ show_source html_blocks.html | grep grep_span
  <p><span>And </span><span as-html><blink>grep_span</blink></span><span>.</span></p>

  $ show_source html_blocks.html | grep "external_inline_grep"
  <p><span>I can include external </span><span id="external_inline_grep">Yo!</span><span>.</span></p>

  $ show_source html_blocks.html | grep -C 10 "external_block"
  <div class="slip">
  <div class="slip-body">
  <div src=html_blocks.md include>
  <pre><code class="language-html">not html
  </code></pre>
  <b id="grep_block">is html</b>
  <p><span>Some </span><code>code span</code><span>.</span></p>
  <p><span>And </span><span as-html><blink>grep_span</blink></span><span>.</span></p>
  <p><span>I can include external </span><span id="external_inline_grep">Yo!</span><span>.</span></p>
  <div src=block.html include>
  <div id="external_block">This is a block</div></div>
  </div>
  </div>
  </div>
  </div>
  
            </div>
            <div id="slip-touch-controls">
              <div class="slip-previous">←</div>
              <div class="slip-fullscreen">⇱</div>
              <div class="slip-next">→</div>

$ cp carousel.html /tmp/
