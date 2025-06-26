open Undoable.Syntax

let do_to_root elem f =
  let is_root elem =
    Brr.El.class' (Jstr.v "slip") elem
    || (Option.is_some @@ Brr.El.at (Jstr.v "pause-block") elem)
  in
  let rec do_rec elem =
    if is_root elem then Undoable.return ()
    else
      let> () = f elem in
      match Brr.El.parent elem with
      | None -> Undoable.return ()
      | Some elem -> do_rec elem
  in
  do_rec elem

let setup_pause elem =
  let> () = Undoable.Browser.set_class "pauseTarget" true elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      let> () = Undoable.Browser.set_class "pauseAncestor" true elem in
      Undoable.Browser.set_at "pauseAncestorMultiplicity"
        (Some (Jstr.of_int 1))
        elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Undoable.Browser.set_class "pauseAncestor" true elem
      | Some i ->
          let> () =
            Undoable.Browser.set_at "pauseAncestorMultiplicity"
              (Some (Jstr.of_int (i + 1)))
              elem
          in
          Undoable.Browser.set_class "pauseAncestor" true elem)

let pause elem =
  let> () = Undoable.Browser.set_class "pauseTarget" false elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      Brr.Console.(
        log [ "Error: pauseAncestorMultiplicity was supposed to be some"; elem ]);
      Undoable.Browser.set_class "pauseAncestor" false elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Undoable.Browser.set_class "pauseAncestor" false elem
      | Some i when i <= 1 ->
          let> () =
            Undoable.Browser.set_at "pauseAncestorMultiplicity" None elem
          in
          Undoable.Browser.set_class "pauseAncestor" false elem
      | Some i ->
          Undoable.Browser.set_at "pauseAncestorMultiplicity"
            (Some (Jstr.of_int (i - 1)))
            elem)

let up window elem = Universe.Move.up window elem
let down window elem = Universe.Move.down window elem
let center window elem = Universe.Move.center window elem

module Enter = struct
  type t = { elem : Brr.El.t; coord : Universe.Coordinates.window }

  let stack = Stack.create ()

  let in_ elem =
    Undoable.Stack.push { elem; coord = Universe.State.get_coord () } stack
end

let enter window elem =
  let> () = Enter.in_ elem in
  Universe.Move.enter window elem

let exit window to_elem =
  let rec exit () =
    let coord = Undoable.Stack.peek Enter.stack in
    match coord with
    | None -> Undoable.return ()
    | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
        Undoable.return ()
    | Some { coord; _ } -> (
        let> _ = Undoable.Stack.pop_opt Enter.stack in
        match Undoable.Stack.peek Enter.stack with
        | None -> Universe.Move.move window coord ~delay:1.0
        | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
            Universe.Move.move window coord ~delay:1.0
        | Some _ -> exit ())
  in
  exit ()

let unstatic elems =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" true) elems

let static elem =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" false) elem

let focus window elems =
  let> () = State.Focus.push (Universe.State.get_coord ()) in
  (* We focus 1px more in order to avoid off-by-one error due to round errors *)
  Universe.Move.focus ~margin:(-1.) window elems

let unfocus window () =
  let> coord = State.Focus.pop () in
  match coord with
  | None -> Undoable.return ()
  | Some coord -> Universe.Move.move window coord ~delay:1.0

let reveal elem =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" false) elem

let unreveal elems =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" true) elems

let emph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" true) elems

let unemph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" false) elems

let scroll window elem = Universe.Move.scroll window elem
