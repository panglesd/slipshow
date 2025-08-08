let step = ref 0
let get_step () = !step

let incr_step () =
  let old_step = !step in
  let undo () = Fut.return (step := old_step) in
  Undoable.return ~undo @@ incr step

module Focus = struct
  let stack = Stack.create ()

  let push c =
    let undo () = Fut.return @@ ignore @@ Stack.pop stack in
    Undoable.return ~undo (Stack.push c stack)

  let pop () =
    let value = Stack.pop_opt stack in
    let undo () =
      Fut.return @@ Option.iter (fun v -> Stack.push v stack) value
    in
    Undoable.return ~undo value
end
