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
  scale : float Lwd.var;
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
  final_d : Brr.At.t Lwd.t;
}

let make_stro ~id ~scale ~path ~color ~stroker ~width ~track ~erased =
  let scale = Lwd.var scale
  and path = Lwd.var path
  and color = Lwd.var color
  and width = Lwd.var width
  and selected = Lwd.var false
  and preselected = Lwd.var false
  and track = Lwd.var track
  and erased = Lwd.var erased in
  let starts_at l = List.hd (List.rev l) |> snd in
  let end_at l = List.hd l |> snd in
  let end_at = Lwd.map (Lwd.get path) ~f:end_at in
  let starts_at = Lwd.map (Lwd.get path) ~f:starts_at in
  let final_d =
    let open Lwd_infix in
    let$* width = Lwd.get width and$ scale = Lwd.get scale in
    let kind =
      match stroker with Pen -> `Pfh width | Highlighter -> `Normal
    in
    Path_editing.make_d kind ~elapsed_time:None ~scale path
  in
  {
    id;
    scale;
    path;
    end_at;
    starts_at;
    color;
    stroker;
    width;
    selected;
    preselected;
    track;
    erased;
    final_d;
  }

type strokes = stro Lwd_table.t

type pause = {
  p_selected : bool Lwd.var;
  p_preselected : bool Lwd.var;
  p_at : float Lwd.var;
}

type pauses = pause Lwd_table.t

type recording = {
  strokes : strokes;
  pauses : pauses;
  total_time : float Lwd.var;
  name : string;
  record_id : int;
  file_path : string;
  element_anchor : Brr.El.t * [ `Anchored | `Unanchored ] Lwd.var;
}

type replaying_state = {
  recording : recording;
  time : float Lwd.var;
  is_playing : bool Lwd.var;
}

type workspaces = {
  recordings : replaying_state Lwd_table.t;
  live_drawing : strokes;
}

type live_drawing_tool = Stroker of stroker | Eraser | Pointer

type live_drawing_state = {
  tool : live_drawing_tool Lwd.var;
  color : color Lwd.var;
  width : width Lwd.var;
}

type editing_tool = Select | Move | Rescale

module StringMap = Map.Make (String)

type recording_state = {
  replaying_state : replaying_state;
  replayed_part : strokes;
  unplayed_erasure : erased StringMap.t;
  recording_temp : strokes;
  started_at : float;
}

type drawing_status = Presenting | Recording of recording_state
type status = Drawing of drawing_status | Editing | Gui_mode
