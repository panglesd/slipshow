let coordinates =
  ref
    {
      Coordinates.x = Constants.width /. 2.;
      y = Constants.height /. 2.;
      scale = 1.;
    }

let set_coord v = coordinates := v
let get_coord () = !coordinates

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
