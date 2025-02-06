let coordinates =
  ref
    {
      Coordinates.x = Constants.width /. 2.;
      y = Constants.height /. 2.;
      scale = 1.;
    }

let set_coord v = coordinates := v
let get_coord () = !coordinates
let step = ref 0
let get_step () = !step

let incr_step () =
  let old_step = !step in
  let undo () = Fut.return (step := old_step) in
  UndoMonad.return ~undo @@ incr step

module Focus = struct
  let stack = Stack.create ()

  let push c =
    let undo () = Fut.return @@ ignore @@ Stack.pop stack in

    UndoMonad.return ~undo (Stack.push c stack)

  let pop () =
    let value = Stack.pop stack in
    let undo () = Fut.return @@ Stack.push value stack in
    UndoMonad.return ~undo value
end
