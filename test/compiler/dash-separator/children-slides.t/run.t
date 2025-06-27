  $ slipshow compile slides.md

  $ cat slides.html | htmlq -p "#slides"
  
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
          <p>
            <span>
              Hello!</span>
          </p>
        </div>
      </div>
    </div>
  </div>
  $ cat slides.html | htmlq -p "#classes"
  
  <div children:.custom-class="" id="classes">
    <div class="custom-class">
      <p><span>A</span>
      </p>
    </div>
    <div class="other custom-class">
      <p>
        <span>
          B</span>
      </p>
    </div>
  </div>
  $ cat slides.html | htmlq -p "#attributes"
  
  <div children:key="value" id="attributes">
    <div key="value">
      <p><span>This is a first slide</span>
      </p>
    </div>
    <div key="value">
      <p>
        <span>
          This is a second slide</span>
      </p>
    </div>
    <div k="v" key="other value">
      <p>
        <span>
          Hello!</span>
      </p>
    </div>
  </div>

$ cp slides.html /tmp/my-slides.html
