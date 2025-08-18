We can compile the file using the slip_of_mark binary

  $ slipshow compile slip.md
  slipshow: [WARNING] Could not read file: img.png. Considering it as an URL. (img.png: No such file or directory)

  $ show_source slip.html | grep "<body>" -A 10
    <body>
      <div id="slipshow-main">
        <div id="slipshow-content">
          <svg id="slipshow-drawing-elem" style="overflow:visible; position: absolute; z-index:1000"></svg>
          <div class="slipshow-rescaler" slip enter-at-unpause>
  <div class="slip">
  <div class="slip-body">
  <div>
  <p><span>A paragraph with an </span><img src="img.png" alt="image" ></p>
  <p id="id" class="class" key=value><img src="img.png" alt="" ></p>
  <p><img src="img.png" alt="" id="id2" class="class2" key2=value2 ></p>
