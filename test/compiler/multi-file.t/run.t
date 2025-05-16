Let's compile the file and check file inclusion

  $ slipshow compile main.md

$ cp main.html /tmp/

  $ slipshow markdown -o - main.md
  # A title
  
  ## Chapter 1
  
  Hello! How are you?
  
  
  Hello! How are you?
  
  
  ## Chapter 2
  
  I am the chapter 2  and I consist of two parts:
  
  ### Part 1
  This is Part 1
  
  
  ### Part 2
  This is Part 2 and it includes an image:
  
  ![](data:;base64,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)
  
  
  $ grep -A 10 "class=\"slip-body" main.html
  <div class="slip-body">
  <h1 id="a-title"><a class="anchor" aria-hidden="true" href="#a-title"></a><span>A title</span></h1>
  <h2 id="chapter-1"><a class="anchor" aria-hidden="true" href="#chapter-1"></a><span>Chapter 1</span></h2>
  <div include src=chapter1.md>
  <p><span>Hello! How are you?</span></p>
  </div>
  <div class="slipshow-rescaler" include src=chapter1.md slip>
  <div class="slip">
  <div class="slip-body">
  <p><span>Hello! How are you?</span></p>
  </div>
  </div>
  </div>
  <h2 id="chapter-2" pause><a class="anchor" aria-hidden="true" href="#chapter-2"></a><span>Chapter 2</span></h2>
  <div include src="chapter2/chapter2.md" pause>
  <p><span>I am the chapter 2 </span><span pause></span><span> and I consist of two parts:</span></p>
  <h3 id="part-1"><a class="anchor" aria-hidden="true" href="#part-1"></a><span>Part 1</span></h3>
  <div include src="parts/part1.md">
  <p><span>This is Part 1</span></p>
