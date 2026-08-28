No tachyon is included by default

  $ cat > main.slp <<EOF
  > {.red}
  > Red text
  > EOF

  $ slipshow compile main.slp
  $ grep "\.bg-red" main.html 
  [1]

Tachyon should be included from the frontmatter
  $ cat > main.slp <<EOF
  > ---
  > tachyons: true
  > ---
  > {.red}
  > Red text
  > EOF

  $ slipshow compile main.slp
  $ grep "\.bg-red" main.html | cut -b 1-1000
  /*! normalize.css v8.0.0 | MIT License | github.com/necolas/normalize.css */.border-box{box-sizing:border-box}.aspect-ratio{height:0;position:relative}.aspect-ratio--16x9{padding-bottom:56.25%}.aspect-ratio--9x16{padding-bottom:177.77%}.aspect-ratio--4x3{padding-bottom:75%}.aspect-ratio--3x4{padding-bottom:133.33%}.aspect-ratio--6x4{padding-bottom:66.6%}.aspect-ratio--4x6{padding-bottom:150%}.aspect-ratio--8x5{padding-bottom:62.5%}.aspect-ratio--5x8{padding-bottom:160%}.aspect-ratio--7x5{padding-bottom:71.42%}.aspect-ratio--5x7{padding-bottom:140%}.aspect-ratio--1x1{padding-bottom:100%}.aspect-ratio--object{position:absolute;top:0;right:0;bottom:0;left:0;width:100%;height:100%;z-index:100}.cover{background-size:cover!important}.contain{background-size:contain!important}.bg-center{background-position:50%}.bg-center,.bg-top{background-repeat:no-repeat}.bg-top{background-position:top}.bg-right{background-position:100%}.bg-bottom,.bg-right{background-repeat:no-repeat}.bg-bottom{background-

No typo allowed!


  $ cat > main.slp <<EOF
  > ---
  > tachyons: oui
  > ---
  > {.red}
  > Red text
  > EOF

  $ slipshow compile main.slp
  warning: Error while parsing frontmatter field 'tachyons'
      ┌─ main.slp:2:11
    2 │  tachyons: oui
      │            ^^^ The only allowed value is 'tachyons'
  
  $ grep "\.bg-red" main.html 
  [1]

