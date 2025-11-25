type color = string

module Width = struct
  type t = float

  let small = 5.
  let medium = 10.
  let large = 20.
end

type width = Width.t
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
  width : width Lwd.var;
  selected : bool Lwd.var;
  preselected : bool Lwd.var;
  track : int Lwd.var;
  erased : erased option Lwd.var;
}

type strokes = stro Lwd_table.t

type recording = {
  strokes : strokes;
  total_time : float Lwd.var;
  name : string Lwd.var;
  record_id : int;
}

type replaying_state = { recording : recording; time : float Lwd.var }

type workspaces = {
  recordings : replaying_state Lwd_table.t;
  live_drawing : strokes;
  current_recording : replaying_state;
}

type live_drawing_tool = Stroker of stroker | Eraser | Pointer

type live_drawing_state = {
  tool : live_drawing_tool Lwd.var;
  color : color Lwd.var;
  width : width Lwd.var;
}

type editing_tool = Select | Move | Rescale

type editing_state = {
  replaying_state : replaying_state;
  is_playing : bool Lwd.var;
}

module StringMap = Map.Make (String)

type recording_state = {
  replaying_state : replaying_state;
  replayed_part : strokes;
  unplayed_erasure : erased StringMap.t;
  recording_temp : strokes;
  started_at : float;
}

type drawing_status = Presenting | Recording of recording_state
type status = Drawing of drawing_status | Editing
