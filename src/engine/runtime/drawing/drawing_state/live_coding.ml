type color = string
type width = float
type stroker = Pen | Highlighter

type erased = {
  at : float Lwd.var;
  track : int Lwd.var;
  selected : bool Lwd.var;
  preselected : bool Lwd.var;
}

type stro = {
  id : string;
  scale : float;
  path :
    ((float * float) * float) list Lwd.var (* TODO: (position * time) list *);
  end_at : float Lwd.t;
  starts_at : float Lwd.t;
  color : color Lwd.var;
  stroker : stroker;
  width : width;
  selected : bool Lwd.var;
  preselected : bool Lwd.var;
  track : int Lwd.var;
  erased : erased option Lwd.var;
}

type strokes = stro Lwd_table.t

type recording = {
  strokes : stro Lwd_table.t;
  total_time : float Lwd.var;
  record_id : int;
}

type workspaces = { recordings : recording Lwd_table.t; live_drawing : strokes }

let workspaces : workspaces =
  { recordings = Lwd_table.make (); live_drawing = Lwd_table.make () }

type live_drawing_tool = Stroker of stroker | Eraser | Pointer

type live_drawing_state = {
  tool : live_drawing_tool Lwd.var;
  color : color Lwd.var;
  width : width Lwd.var;
}

(* type recording_state = { *)
(* live_drawing_state : live_drawing_state; *)
(* recording : recording; *)
(* } *)

type editing_tool = Select | Move | Rescale

let editing_tool = Lwd.var Select

type editing_state = {
  recording : recording;
  current_time : float Lwd.var;
  is_playing : bool Lwd.var;
}

type recording_state = { recording : recording; started_at : float }

let live_drawing_state =
  { tool = Lwd.var Pointer; color = Lwd.var "blue"; width = Lwd.var 10.0 }

type drawing_status = Presenting | Recording of recording_state
type status = Drawing of drawing_status | Editing of editing_state

let status = Lwd.var (Drawing Presenting)
