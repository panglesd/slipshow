open Types

let workspaces : workspaces =
  { recordings = Lwd_table.make (); live_drawing = Lwd_table.make () }

let editing_tool = Lwd.var Select
let current_replaying_state : replaying_state option Lwd.var = Lwd.var None

let live_drawing_state =
  {
    tool = Lwd.var Pointer;
    color = Lwd.var "blue";
    width = Lwd.var Width.medium;
  }
