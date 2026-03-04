We can compile the file using the slip_of_mark binary

  $ slipshow compile video.md
  warning: Wrong type
      ┌─ video.md:7:1
    7 │  {play-media}
      │  ^^^^^^^^^^^^
      │  │
      │  This expects the id of a video or audio
      │  This is not a video or audio
  
  warning: No element with id 'inexistent-id' was found
      ┌─ video.md:5:14
    5 │  {play-media="inexistent-id"}
      │               ^^^^^^^^^^^^^ This should be an ID present in the document
  

$ cp slip.html /tmp/slip.html
