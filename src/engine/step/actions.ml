open Undoable.Syntax

let up window elem = Universe.Window.up window elem
let down window elem = Universe.Window.down window elem
let center window elem = Universe.Window.center window elem
let enter window elem = Universe.Window.enter window elem

let unstatic elems =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" true) elems

let static elem =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" false) elem

let focus window elems =
  let> () = State.Focus.push (Universe.State.get_coord ()) in
  (* We focus 1px more in order to avoid off-by-one error due to round errors *)
  Universe.Window.focus ~margin:(-1.) window elems

let unfocus window () =
  let> coord = State.Focus.pop () in
  match coord with
  | None -> Undoable.return ()
  | Some coord -> Universe.Window.move window coord ~delay:1.0

let reveal elem =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" false) elem

let unreveal elems =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" true) elems

let emph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" true) elems

let unemph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" false) elems

let scroll window elem = Universe.Window.scroll window elem
