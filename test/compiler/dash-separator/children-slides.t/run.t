  $ slipshow compile slides.md
  warning: Non standard attribute: 'key'
      ┌─ slides.md:24:2
   24 │  {children:key=value #attributes}
      │   ^^^^^^^^^^^^ 
  
  warning: Non standard attribute: 'k'
      ┌─ slides.md:33:2
   33 │  {k=v key="other value"}
      │   ^ 
  
  warning: Non standard attribute: 'key'
      ┌─ slides.md:33:6
   33 │  {k=v key="other value"}
      │       ^^^ 
  
  warning: Non standard attribute: 'key'
      ┌─ slides.md:24:2
   24 │  {children:key=value #attributes}
      │   ^^^^^^^^^^^^ 
  
  warning: Non standard attribute: 'key'
      ┌─ slides.md:24:2
   24 │  {children:key=value #attributes}
      │   ^^^^^^^^^^^^ 
  
  warning: Non standard attribute: 'key'
      ┌─ slides.md:24:2
   24 │  {children:key=value #attributes}
      │   ^^^^^^^^^^^^ 
  
  warning: Non standard attribute: 'key'
      ┌─ slides.md:24:2
   24 │  {children:key=value #attributes}
      │   ^^^^^^^^^^^^ 
  

  $ show_source slides.html | htmlq -p "#slides"
  
  <div children:slide="" id="slides" style="display:flex">
    <div class="slipshow-rescaler" enter-at-unpause="" slide="">
      <div class="slide">
        <div class="slide-body">
          <p><span>This is a first slide</span>
          </p>
        </div>
      </div>
    </div>
    <div class="slipshow-rescaler" enter-at-unpause="" slide="">
      <div class="slide">
        <div class="slide-body">
          <hr>
          
        </div>
      </div>
    </div>
    <div class="slipshow-rescaler" enter-at-unpause="" slide="">
      <div class="slide">
        <div class="slide-body">
          <p>
            <span>
              This is a second slide</span>
          </p>
        </div>
      </div>
    </div>
    <div class="slipshow-rescaler" enter-at-unpause="" slide="">
      <div class="slide">
        <div class="slide-body">
          <hr>
          
        </div>
      </div>
    </div>
    <div class="slipshow-rescaler" enter-at-unpause="" slide="">
      <div class="slide">
        <div class="slide-body">
          <p>
            <span>
              Hello!</span>
          </p>
        </div>
      </div>
    </div>
  </div>
  $ show_source slides.html | htmlq -p "#classes"
  
  <div children:.custom-class="" id="classes">
    <p class="custom-class"><span>A</span>
    </p>
    <hr class="custom-class other">
    
    <p class="custom-class">
      <span>
        B</span>
    </p>
  </div>
  $ show_source slides.html | htmlq -p "#attributes"
  
  <div children:key="value" id="attributes">
    <p key="value"><span>This is a first slide</span>
    </p>
    <hr key="value">
    
    <p key="value">
      <span>
        This is a second slide</span>
    </p>
    <hr k="v" key="value">
    
    <p key="value">
      <span>
        Hello!</span>
    </p>
  </div>

$ cp slides.html /tmp/my-slides.html
