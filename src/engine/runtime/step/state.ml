let get_step (global : Global_state.t) = global.step
let set_step (global : Global_state.t) s = global.step <- s

let incr_step (global : Global_state.t) =
  let old_step = global.step in
  let undo () = Fut.return (global.step <- old_step) in
  Undoable.return ~undo @@ (global.step <- global.step + 1)
