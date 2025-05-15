We can compile the file using the slip_of_mark binary

  $ slipshow compile slides.md

  $ cat slides.html | grep "<body>" -A 15
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler">
  <div class="slip">
  <div class="slip-body">
  <div style="display: flex">
  <div id="slide1" class="slipshow-rescaler" slide style="flex: 1 1 auto;">
  <div class="slide">
  <div class="slide-body">
  <p><span>Aren’t you just bored with all those slides-based presentations?</span></p>
  </div>
  </div>
  </div>
  <div id="slide2" class="slipshow-rescaler" slide style="flex: 1 1 auto;">

  $ cp slides.html /tmp/
