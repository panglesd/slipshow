let now () = Brr.Performance.now_ms Brr.G.performance

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

type recording_state = {
  replaying_state : replaying_state;
  recording_temp : strokes;
  started_at : float;
}

let live_drawing_state =
  {
    tool = Lwd.var Pointer;
    color = Lwd.var "blue";
    width = Lwd.var Width.medium;
  }

type drawing_status = Presenting | Recording of recording_state
type status = Drawing of drawing_status | Editing

let status = Lwd.var (Drawing Presenting)

let start_recording replaying_state =
  (* let strokes = Lwd_table.make () in *)
  Lwd.set status
    (Drawing
       (Recording
          {
            replaying_state;
            started_at =
              now () (* -. Lwd.peek replaying_state.recording.total_time *);
            recording_temp = Lwd_table.make ();
          }))

let finish_recording { replaying_state; started_at; recording_temp } =
  let additional_time = now () -. started_at in
  Lwd_table.iter
    (fun stro ->
      if Lwd.peek stro.path |> List.hd |> snd >= Lwd.peek replaying_state.time
      then
        Lwd.update
          (List.map @@ fun (pos, t) -> (pos, t +. additional_time))
          stro.path
      else ();
      match Lwd.peek stro.erased with
      | None -> ()
      | Some { at; _ } ->
          if Lwd.peek at >= Lwd.peek replaying_state.time then
            Lwd.update (( +. ) additional_time) at)
    replaying_state.recording.strokes;
  Lwd_table.iter
    (fun stro ->
      Lwd.update
        (List.map @@ fun (x, t) -> (x, t +. Lwd.peek replaying_state.time))
        stro.path)
    recording_temp;
  Lwd.update (( +. ) additional_time) replaying_state.recording.total_time;
  Lwd.update (( +. ) additional_time) replaying_state.time;
  Lwd_table.iter
    (fun stro -> Lwd_table.append' replaying_state.recording.strokes stro)
    recording_temp;
  Lwd.set status Editing
