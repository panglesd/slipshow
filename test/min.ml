open Brr
let () =
  El.set_children (Document.body G.document) El.[txt' "Hello World!"]
