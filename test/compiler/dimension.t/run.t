We can provide the dimension with dimension

  $ cat > file.md << EOF
  > ---
  > dimension: qfdesfesf
  > ---
  > EOF
  $ slipshow compile file.md
  warning: Error while parsing frontmatter field 'dimension'
      ┌─ file.md:2:11
    2 │  dimension: qfdesfesf
      │            ^^^^^^^^^^ Expected "4:3", "16:9", or two integers separated by a 'x'
  

  $ cat > file.md << EOF
  > ---
  > dimension: wrongxefzefezf
  > ---
  > EOF
  $ slipshow compile file.md
  warning: Error while parsing frontmatter field 'dimension'
      ┌─ file.md:2:11
    2 │  dimension: wrongxefzefezf
      │            ^^^^^^^^^^^^^^^ Expected "4:3", "16:9", or two integers separated by a 'x'
  

  $ cat > file.md << EOF
  > ---
  > dimension: 1920xwrong
  > ---
  > EOF
  $ slipshow compile file.md
  warning: Error while parsing frontmatter field 'dimension'
      ┌─ file.md:2:11
    2 │  dimension: 1920xwrong
      │            ^^^^^^^^^^^ Expected "4:3", "16:9", or two integers separated by a 'x'
  

  $ cat > file.md << EOF
  > ---
  > dimension: 16:9
  > ---
  > EOF
  $ slipshow compile file.md

  $ cat > file.md << EOF
  > ---
  > dimension: 4:3
  > ---
  > EOF
  $ slipshow compile file.md

  $ cat > file.md << EOF
  > ---
  > dimension: 1920x1080
  > ---
  > EOF
  $ slipshow compile file.md
