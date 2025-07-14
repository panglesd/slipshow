We can compile the file using the slip_of_mark binary

  $ slipshow compile slides.md

  $ cat slides.html | grep "<body>" -A 16
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler" slip enter-at-unpause>
  <div class="slip">
  <div class="slip-body">
  <div>
  <div style="display: flex">
  <div id="slide1" class="slipshow-rescaler" slide enter-at-unpause>
  <div class="slide">
  <div class="slide-title">
  <span>First title</span></div>
  <div class="slide-body">
  <p><span>Aren’t you just bored with all those slides-based presentations?</span></p>
  </div>
  </div>

$ cp slides.html /tmp/
