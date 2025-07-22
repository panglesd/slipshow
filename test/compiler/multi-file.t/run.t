Let's compile the file and check file inclusion

  $ slipshow compile main.md

$ cp main.html /tmp/

  $ slipshow markdown -o - main.md
  # A title
  
  ## Chapter 1
  
  Hello! How are you?
  
  
  ## Chapter 2
  
  I am the chapter 2  and I consist of two parts:
  
  ### Part 1
  This is Part 1
  
  
  ### Part 2
  This is Part 2 and it includes an image:
  
  ![](chapter2/image_of_chapter_2.png)
  
  
  $ grep -A 11 "class=\"slip-body" main.html
  <div class="slip-body">
  <div>
  <h1 id="a-title"><a class="anchor" aria-hidden="true" href="#a-title"></a><span>A title</span></h1>
  <h2 id="chapter-1"><a class="anchor" aria-hidden="true" href="#chapter-1"></a><span>Chapter 1</span></h2>
  <div src=chapter1.md include>
  <p><span>Hello! How are you?</span></p>
  </div>
  <h2 id="chapter-2" pause><a class="anchor" aria-hidden="true" href="#chapter-2"></a><span>Chapter 2</span></h2>
  <div pause src="chapter2/chapter2.md" include>
  <p><span>I am the chapter 2 </span><span pause></span><span> and I consist of two parts:</span></p>
  <h3 id="part-1"><a class="anchor" aria-hidden="true" href="#part-1"></a><span>Part 1</span></h3>
  <div src="parts/part1.md" include>
