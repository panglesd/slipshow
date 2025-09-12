module Stroke = State.Stroke

let init () = Setup.init ()

let set_record (s : Drawing.Action.Record.record option) =
  State.Recording.set_current s
