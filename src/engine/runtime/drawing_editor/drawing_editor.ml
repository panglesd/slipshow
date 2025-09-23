module Stroke = State.Stroke

let init () = Setup.init ()

let set_record (s : Drawing.Action.Record.t option) =
  State.Recording.set_current s
