Frontmatter delimiters accept trailing spaces and tabs with LF line endings.

  $ printf '%b' '---  \ndimension: invalid\n---\t\n' > lf.md
  $ slipshow compile lf.md 2>&1 | grep "Error while parsing frontmatter field"
  warning: Error while parsing frontmatter field 'dimension'

Frontmatter delimiters accept trailing spaces and tabs with CRLF line endings.

  $ printf '%b' '---\t\r\ndimension: invalid\r\n---  \r\n' > crlf.md
  $ slipshow compile crlf.md 2>&1 | grep "Error while parsing frontmatter field"
  warning: Error while parsing frontmatter field 'dimension'
