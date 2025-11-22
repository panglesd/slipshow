let step = ref 0
let get_step () = !step
let set_step = ( := ) step

let incr_step () =
  let old_step = !step in
  let undo () = Fut.return (step := old_step) in
  Undoable.return ~undo @@ incr step
