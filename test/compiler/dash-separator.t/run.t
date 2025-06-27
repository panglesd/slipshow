

  $ slipshow compile dash-sep.md

  $ slipshow compile normal-divs.md

  $ scp dash-sep.html /tmp/
  $ scp normal-divs.html /tmp/

Asterisks are still interpreted as horizontal lines

  $ grep Asterisks -A 2 dash-sep.html
  <p><span>Asterisks still allow horizontal lines:</span></p>
  <hr>
  <p><span>For instance this one</span></p>

However, dash lines are used as separator to group in divs

  $ cat dash-sep.html | htmlq ".show-border" -p
  
  <div class="show-border">
    <p><span>aa</span>
    </p>
    <div>
      <p>
        <span>
          bbb</span>
      </p>
      <p>
        <span>
          ccc</span>
      </p>
      <p>
        <span>
          ddd</span>
      </p>
    </div>
    <p>
      <span>
        ee</span>
    </p>
  </div>

  $ grep "class=\"show-border\"" -A 8 dash-sep.html
  <div class="show-border">
  <p><span>aa</span></p>
  <div>
  <p><span>bbb</span></p>
  <p><span>ccc</span></p>
  <p><span>ddd</span></p>
  </div>
  <p><span>ee</span></p>
  </div>

  $ cat normal-divs.html | htmlq ".show-border" -p
  
  <div class="show-border">
    <p><span>aa</span>
    </p>
    <div>
      <p>
        <span>
          bbb</span>
      </p>
      <p>
        <span>
          ccc</span>
      </p>
      <p>
        <span>
          ddd</span>
      </p>
    </div>
    <p>
      <span>
        ee</span>
    </p>
  </div>

  $ grep "class=\"show-border\"" -A 8 normal-divs.html
  <div class="show-border">
  <p><span>aa</span></p>
  <div>
  <p><span>bbb</span></p>
  <p><span>ccc</span></p>
  <p><span>ddd</span></p>
  </div>
  <p><span>ee</span></p>
  </div>
