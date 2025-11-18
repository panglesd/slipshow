let now () = Brr.Performance.now_ms Brr.G.performance

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

let workspaces : workspaces =
  {
    recordings = Lwd_table.make ();
    live_drawing = Lwd_table.make ();
    current_recording =
      {
        recording =
          {
            strokes = Lwd_table.make ();
            total_time = Lwd.var 0.;
            record_id = Random.bits ();
            name = Lwd.var "Unnamed recording";
          };
        time = Lwd.var 0.;
      };
  }

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
  replaying_state : replaying_state;
  is_playing : bool Lwd.var;
}

let current_editing_state =
  Lwd.var
    {
      replaying_state = workspaces.current_recording;
      is_playing = Lwd.var false;
    }

type recording_state = { (* strokes : strokes;  *) started_at : float }

let live_drawing_state =
  { tool = Lwd.var Pointer; color = Lwd.var "blue"; width = Lwd.var 15.0 }

type drawing_status = Presenting | Recording of recording_state
type status = Drawing of drawing_status | Editing

let status = Lwd.var (Drawing Presenting)

let start_recording () =
  (* let strokes = Lwd_table.make () in *)
  Lwd.set status
    (Drawing
       (Recording
          {
            (* strokes; *)
            started_at =
              now ()
              -. Lwd.peek workspaces.current_recording.recording.total_time;
          }))

let finish_recording recording_state =
  let new_total_time = now () -. recording_state.started_at in
  (* let new_strokes = recording_state.strokes in *)
  let current_editing_state = Lwd.peek current_editing_state in
  (* Lwd_table.concat current_recording.strokes new_strokes; *)
  Lwd.set current_editing_state.replaying_state.recording.total_time
    (* Lwd.peek current_recording.total_time +.  *) new_total_time;
  Lwd.set current_editing_state.replaying_state.time new_total_time;
  (* let replaying_state = *)
  (*   { *)
  (*     recording = workspaces.current_recording.recording; *)
  (*     time = Lwd.var new_total_time; *)
  (*   } *)
  (* in *)
  (* Lwd.set recording_state.recording.total_time total_time; *)
  Lwd.set status Editing (* { replaying_state; is_playing = Lwd.var false } *)

let toggle_recording mode =
  match mode with
  | Presenting -> start_recording ()
  | Recording recording -> finish_recording recording
