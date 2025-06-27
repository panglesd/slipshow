  $ slipshow compile dash-sep.md

Asterisks are still interpreted as horizontal lines

  $ grep Asterisks -A 2 dash-sep.html
  <p><span>Asterisks still allow horizontal lines:</span></p>
  <hr>
  <p><span>For instance this one</span></p>

However, dash lines are used as separator to group in divs

  $ cat dash-sep.html | htmlq ".show-border1" -p
  
  <div class="show-border1">
    <div>
      <p><span>aaa</span>
      </p>
      <p>
        <span>
          bbb</span>
      </p>
    </div>
    <p>
      <span>
        cc</span>
    </p>
    <div>
      <p>
        <span>
          ddd</span>
      </p>
      <p>
        <span>
          eee</span>
      </p>
    </div>
  </div>

  $ cat dash-sep.html | htmlq ".show-border2" -p
  
  <div class="show-border2">
    <p><span>aa</span>
    </p>
    <p>
      <span>
        bb</span>
    </p>
  </div>

  $ cat dash-sep.html | htmlq ".show-border3" -p
  
  <div class="show-border3">
    <div class="c1">
      <p><span>aa</span>
      </p>
    </div>
    <div class="c2">
      <p>
        <span>
          bb</span>
      </p>
    </div>
  </div>
