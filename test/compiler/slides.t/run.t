We can compile the file using the slip_of_mark binary

  $ slipshow compile file.md

  $ cat file.html | grep "<body>" -A 15
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler">
            <div class="slip">
              <div class="slip-body">
                <div class="slipshow-rescaler">
  <div id="idslide" class="slide" slide>
  <p><span>Hello this is a slide</span></p>
  </div>
  </div>
  <p><span>Hello</span></p>
  <p focus-at-unpause=idslide pause><span>yo</span></p>
  <style>
    #idslide {

  $ cp file.html /tmp/
