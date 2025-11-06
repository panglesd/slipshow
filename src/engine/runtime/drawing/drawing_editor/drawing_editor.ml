module Stroke = State.Stroke
module Ui_widgets = Ui_widgets
module Path_editing = Path_editing

let init () = Setup.init ()
let set_record (s : Drawing.Record.t option) = State.Recording.set_current s

module Controller = Controller
