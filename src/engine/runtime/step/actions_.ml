open Undoable.Syntax
open Brr

let ( !! ) = Jstr.v

(** On an invalid selector, this function will raise. Since in this module ids
    are user input, we valide them *)
let find_first_by_selector ?root x =
  try El.find_first_by_selector ?root x
  with e ->
    Console.(error [ e ]);
    None

(* We define the [Actions_] module to avoid a circular dependency: If we had
   only one [Action] module (and not an [Actions] and an [Actions_]) then
   [Actions] would depend on [Javascrip_api] which would depend on [Actions]. *)

module type S = sig
  include Actions_arguments.S

  val setup : (El.t -> args -> unit Fut.t) option
  val setup_all : (unit -> unit Fut.t) option

  type js_args

  val do_js : mode:Fast.mode -> Universe.Window.t -> js_args -> unit Undoable.t

  val do_ :
    mode:Fast.mode -> Universe.Window.t -> El.t -> args -> unit Undoable.t
end

module type Move = sig
  type args = {
    margin : float option;
    duration : float option;
    target : [ `Self | `Id of string Actions_arguments.W.node ];
  }

  type js_args = {
    elem : Brr.El.t;
    duration : float option;
    margin : float option;
  }

  include S with type args := args and type js_args := js_args
end

module type SetClass =
  S
    with type args = [ `Self | `Ids of string Actions_arguments.W.node list ]
     and type js_args = Brr.El.t list

let only_if_not_counting mode f =
  match mode with
  | Fast.Counting_for_toc -> Undoable.return ()
  | Normal _ | Fast | Slow -> f ()

let elems_of_ids_or_self ids_or_self elem =
  match ids_or_self with
  | `Self -> [ elem ]
  | `Ids ids ->
      let handle_none id = function
        | Some _ as x -> x
        | None as x ->
            Console.(error [ "id"; id; "was not found" ]);
            x
      in
      List.filter_map
        (fun (id, _) ->
          El.find_first_by_selector !!("#" ^ id) |> handle_none id)
        ids

let elem_of_id_or_self id_or_self elem ~none some =
  match id_or_self with
  | `Self -> some elem
  | `Id (id, _) -> (
      match El.find_first_by_selector !!("#" ^ id) with
      | None ->
          Console.(error [ "id"; id; "was not found" ]);
          none
      | Some elem -> some elem)

let ( let< ) x f = x f

module Pause = struct
  include Actions_arguments.Pause

  let do_to_root elem f =
    let is_root elem =
      El.class' (Jstr.v "slip") elem
      || El.class' (Jstr.v "slide") elem
      || El.class' (Jstr.v "slipshow-universe") elem
      || (Option.is_some @@ El.at (Jstr.v "pause-block") elem)
    in
    let rec do_rec elem =
      if is_root elem then Undoable.return ()
      else
        let> () = f elem in
        match El.parent elem with
        | None -> Undoable.return ()
        | Some elem -> do_rec elem
    in
    do_rec elem

  open Undoable.Browser

  let update_single elem n =
    if n <= 0 then
      let> () = set_at "pauseAncestorMultiplicity" None elem in
      set_class "pauseAncestor" false elem
    else
      let> () =
        set_at "pauseAncestorMultiplicity" (Some (Jstr.of_int n)) elem
      in
      set_class "pauseAncestor" true elem

  let update elem f =
    do_to_root elem @@ fun elem ->
    let n =
      match El.at (Jstr.v "pauseAncestorMultiplicity") elem with
      | None -> 0
      | Some n -> (
          match Jstr.to_int n with
          | None ->
              Console.(
                log [ "Error: wrong value to pauseAncestorMultiplicity:"; n ]);
              0
          | Some n -> n)
    in
    update_single elem (f n)

  let setup elem =
    let open Fut.Syntax in
    let* (), _ = set_class "pauseTarget" true elem in
    update elem (( + ) 1) |> Undoable.discard

  let setup_all () =
    (* TODO: check if this is really needed *)
    let open Fut.Syntax in
    El.fold_find_by_selector
      (fun elem acc ->
        let* () = acc in
        setup elem)
      (Jstr.v "pause-target") (Fut.return ())

  let setup elem args =
    let elems = elems_of_ids_or_self args elem in
    let open Fut.Syntax in
    List.fold_left
      (fun acc elem ->
        let* () = acc in
        setup elem)
      (Fut.return ()) elems

  let setup = Some setup
  let setup_all = Some setup_all

  type js_args = El.t list

  let do_js ~mode _window elems =
    only_if_not_counting mode @@ fun _mode ->
    elems
    |> Undoable.List.iter @@ fun elem ->
       let> () = set_class "pauseTarget" false elem in
       update elem (fun n -> n - 1)

  let do_ ~mode _window elem args =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self args elem in
    do_js ~mode _window elems
end

module _ : S = Pause

module Move (X : sig
  val on : string
  val action_name : string

  val move :
    ?duration:float ->
    ?margin:float ->
    Fast.mode ->
    Universe.Window.t ->
    El.t ->
    unit Undoable.t
end) =
struct
  include Actions_arguments.Move (X)

  type js_args = { elem : El.t; duration : float option; margin : float option }

  let setup = None
  let setup_all = None

  let do_js ~mode window { elem; margin; duration } =
    only_if_not_counting mode @@ fun _mode ->
    let open Fut.Syntax in
    let* () = Excursion.end_ window () in
    let margin = Option.value ~default:0. margin in
    let duration = Option.value ~default:1. duration in
    X.move ~margin ~duration mode window elem

  let do_ ~mode window elem { margin; duration; target } =
    only_if_not_counting mode @@ fun _mode ->
    let< elem = elem_of_id_or_self target elem ~none:(Undoable.return ()) in
    do_js ~mode window { elem; margin; duration }
end

module SetClass (X : sig
  val on : string
  val action_name : string
  val class_ : string
  val state : bool
end) =
struct
  include Actions_arguments.SetClass (X)

  type js_args = El.t list

  let setup = None
  let setup_all = None

  let do_js ~mode _window elems =
    only_if_not_counting mode @@ fun _mode ->
    Undoable.List.iter (Undoable.Browser.set_class X.class_ X.state) elems

  let do_ ~mode _window elem args =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self args elem in
    do_js ~mode _window elems
end

module Up = Move (struct
  let on = "up-at-unpause"
  let action_name = "up"
  let move = Universe.Move.up
end)

module _ : S = Up

module Down = Move (struct
  let on = "down-at-unpause"
  let action_name = "down"
  let move = Universe.Move.down
end)

module Center = Move (struct
  let on = "center-at-unpause"
  let action_name = "center"
  let move = Universe.Move.center
end)

module Scroll = Move (struct
  let on = "scroll-at-unpause"
  let action_name = "scroll"
  let move = Universe.Move.scroll
end)

module Enter = struct
  type t = {
    element_entered : El.t;  (** The element we entered *)
    coord_left : Universe.Coordinates.window;
        (** The coordinate we left when entering *)
    duration : float option;  (** The duration it took to enter entering *)
  }

  let stack = Stack.create ()

  include Move (struct
    let on = "enter-at-unpause"
    let action_name = "enter"

    let move ?duration ?margin mode window element_entered =
      let> () =
        let coord_left = Universe.State.get_coord () in
        Undoable.Stack.push { element_entered; coord_left; duration } stack
      in
      Universe.Move.enter ?duration ?margin mode window element_entered
  end)
end

let exit ~mode window to_elem =
  let rec exit () =
    let coord = Undoable.Stack.peek Enter.stack in
    match coord with
    | None -> Undoable.return ()
    | Some { element_entered; _ }
      when El.contains element_entered ~child:to_elem ->
        Undoable.return ()
    | Some { coord_left; duration; _ } -> (
        let open Fut.Syntax in
        let* () = Excursion.end_ window () in
        let duration = Option.value duration ~default:1.0 in
        let> _ = Undoable.Stack.pop_opt Enter.stack in
        match Undoable.Stack.peek Enter.stack with
        | None -> Universe.Move.move mode window coord_left ~duration
        | Some { Enter.element_entered; _ }
          when El.contains element_entered ~child:to_elem ->
            let duration =
              match El.at (Jstr.v "enter-at-unpause") to_elem with
              | None -> duration
              | Some s -> (
                  match Enter.parse_args (Jstr.to_string s) with
                  | Error _ -> duration
                  | Ok (v, _warnings) ->
                      Option.value ~default:duration v.duration)
            in
            Universe.Move.move mode window coord_left ~duration
        | Some _ -> exit ())
  in
  exit ()

module Unstatic = SetClass (struct
  let on = "unstatic-at-unpause"
  let action_name = "unstatic"
  let class_ = "unstatic"
  let state = true
end)

module _ : S = Unstatic

module Static = SetClass (struct
  let on = "static-at-unpause"
  let action_name = "static"
  let class_ = "unstatic"
  let state = false
end)

module Focus = struct
  include Actions_arguments.Focus

  module State = struct
    let stack = ref None

    let push c =
      match !stack with
      | None ->
          let undo () = Fut.return @@ (stack := None) in
          Undoable.return ~undo (stack := Some c)
      | Some _ -> Undoable.return ()

    let pop () =
      match !stack with
      | None -> Undoable.return !stack
      | Some v as ret ->
          let undo () = Fut.return @@ (stack := Some v) in
          stack := None;
          Undoable.return ~undo ret
  end

  type js_args = {
    margin : float option;
    duration : float option;
    elems : El.t list;
  }

  let do_js ~mode window { elems; margin; duration } =
    only_if_not_counting mode @@ fun _mode ->
    let open Fut.Syntax in
    let* () = Excursion.end_ window () in
    let> () = State.push (Universe.State.get_coord ()) in
    let margin = Option.value ~default:0. margin in
    let duration = Option.value ~default:1. duration in
    Universe.Move.focus ~margin ~duration mode window elems

  let do_ ~mode window el { target; margin; duration } =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self target el in
    do_js ~mode window { elems; margin; duration }

  let setup = None
  let setup_all = None
end

module _ : S = Focus

module Unfocus = struct
  include Actions_arguments.Unfocus

  let setup = None
  let setup_all = None

  type js_args = unit

  let do_js ~mode window () =
    only_if_not_counting mode @@ fun _mode ->
    let> coord = Focus.State.pop () in
    match coord with
    | None -> Undoable.return ()
    | Some coord ->
        let open Fut.Syntax in
        let* () = Excursion.end_ window () in
        Universe.Move.move mode window coord ~duration:1.0

  let do_ ~mode window _elem () =
    only_if_not_counting mode @@ fun _mode -> do_js ~mode window ()
end

module _ : S = Unfocus

module Reveal = SetClass (struct
  let on = "reveal-at-unpause"
  let action_name = "reveal"
  let class_ = "unrevealed"
  let state = false
end)

module Unreveal = SetClass (struct
  let on = "unreveal-at-unpause"
  let action_name = "unreveal"
  let class_ = "unrevealed"
  let state = true
end)

module Emph = SetClass (struct
  let on = "emph-at-unpause"
  let action_name = "emph"
  let class_ = "emphasized"
  let state = true
end)

module Unemph = SetClass (struct
  let on = "unemph-at-unpause"
  let action_name = "unemph"
  let class_ = "emphasized"
  let state = false
end)

module Step = struct
  include Actions_arguments.Step

  let setup = None
  let setup_all = None

  type js_args = unit

  let do_js ~mode:_ _ _ = Undoable.return ()
  let do_ ~mode:_ _ _ _ = Undoable.return ()
end

module _ : S = Step

module Speaker_note = struct
  include Actions_arguments.Speaker_note

  let sn = ref ""

  let setup elem arg =
    let< elem = elem_of_id_or_self arg elem ~none:(Fut.return ()) in
    Fut.return @@ El.set_class (Jstr.v "__slipshow__speaker_note") true elem

  let setup = Some setup
  let setup_all = None

  type js_args = El.t

  let do_js ~mode:_ (_ : Universe.Window.t) elem =
    let innerHTML = Jv.Jstr.get (El.to_jv elem) "innerHTML" |> Jstr.to_string in
    let old_value = !sn in
    let undo () =
      Messaging.send_speaker_notes old_value;
      sn := old_value;
      Fut.return ()
    in
    sn := innerHTML;
    Messaging.send_speaker_notes !sn;
    Undoable.return ~undo ()

  let do_ ~mode _window elem (arg : args) =
    elem_of_id_or_self arg elem ~none:(Undoable.return ()) @@ fun elem ->
    do_js ~mode _window elem
end

module _ : S = Speaker_note

module Play_media = struct
  include Actions_arguments.Play_media

  type js_args = Brr.El.t list

  let log_error = function Ok () -> () | Error x -> Console.(error [ x ])

  let do_js ~mode _window elems =
    only_if_not_counting mode @@ fun _mode ->
    let is_speaker_note =
      match Window.name G.window |> Jstr.to_string with
      | "slipshow_speaker_view" -> true
      | _ -> false
    in
    Undoable.List.iter
      (fun e ->
        let open Fut.Syntax in
        let is_video = Jstr.equal (Jstr.v "video") @@ El.tag_name e in
        let is_audio = Jstr.equal (Jstr.v "audio") @@ El.tag_name e in
        if (not is_video) && not is_audio then (
          Console.(
            log
              [
                "Action play-media only has effect on video and audio elements:";
                e;
              ]);
          Undoable.return ())
        else
          let e = Brr_io.Media.El.of_el e in
          let () = if is_speaker_note then Brr_io.Media.El.set_muted e true in
          let current = Brr_io.Media.El.current_time_s e in
          let () =
            (* Strangely, without this, at least in my setup, firefox often
               waits several seconds before showing the video, even in a very
               simple html file just playing the file.  *)
            Brr_io.Media.El.set_current_time_s e current
          in
          let is_playing = not @@ Brr_io.Media.El.paused e in
          let undo () =
            let+ res =
              if is_playing then Brr_io.Media.El.play e
              else Fut.return (Ok (Brr_io.Media.El.pause e))
            in
            log_error res;
            Brr_io.Media.El.set_current_time_s e current
          in
          let* () =
            let open Brr_io.Media.El in
            let when_slow hurry_bomb =
              Console.(log [ "Playing" ]);
              let fut, activate = Fut.create () in
              let activate =
                let did = ref false in
                fun () ->
                  let old_did = !did in
                  did := true;
                  if not old_did then activate ()
              in
              let _ =
                let+ () = Fast.wait hurry_bomb in
                let duration = duration_s e in
                if not @@ Float.is_nan duration then
                  set_current_time_s e duration;
                activate ()
              in
              let _unlisten =
                let opts = Ev.listen_opts ~once:true () in
                Ev.listen ~opts Ev.ended
                  (fun _ev -> activate ())
                  (e |> Brr_io.Media.El.to_el |> El.as_target)
              in
              let* err = Brr_io.Media.El.play e in
              match err with
              | Ok () -> fut
              | Error e ->
                  Console.(error [ e ]);
                  activate ();
                  fut
            in
            let when_fast () =
              Console.(log [ "Just setting current time" ]);
              let duration = duration_s e in
              if Float.is_nan duration then Fut.return ()
              else Fut.return @@ set_current_time_s e duration
            in
            match mode with
            | Fast.Normal hurry_bomb when not (Fast.has_detonated hurry_bomb) ->
                when_slow hurry_bomb
            | Slow ->
                when_slow
                  (match Fast.normal () with
                  | Normal h -> h
                  | _ -> assert false)
            | Counting_for_toc | Fast | Normal _ -> when_fast ()
          in
          Undoable.return ~undo ())
      elems

  let do_ ~mode _window elem args =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self args elem in
    do_js ~mode _window elems

  let setup = None
  let setup_all = None
end

module _ : S = Play_media

module Change_page = struct
  include Actions_arguments.Change_page

  let ( let+ ) x f = Result.map f x
  let ( let* ) x f = Result.bind x f

  let handle_error = function
    | Ok x -> Some x
    | Error (`Msg x) ->
        Console.(log [ x ]);
        None

  (* Taken from OCaml 5.2 *)
  let find_mapi f =
    let rec aux i = function
      | [] -> None
      | x :: l -> (
          match f i x with Some _ as result -> result | None -> aux (i + 1) l)
    in
    aux 0

  type js_args = { elem : El.t; change : change }

  let check_carousel elem f =
    if El.class' (Jstr.v "slipshow__carousel") elem then f ()
    else Undoable.return None

  (* TODO: better name... *)
  let do_js' ~mode:_ _window { elem; change } =
    check_carousel elem @@ fun () ->
    let children = El.children ~only_els:true elem in
    let current_index =
      find_mapi
        (fun i x ->
          if El.class' (Jstr.v "slipshow__carousel_active") x then Some (i, x)
          else None)
        children
    in
    let new_index =
      match (change, current_index) with
      | Range (a, _), _ -> a
      | Absolute i, _ -> i - 1
      | Relative r, Some (i, _) -> i + r
      | All, Some (i, _) -> i + 1
      | _ ->
          Console.(log [ "Error during carousel" ]);
          0
    in
    let new_index = Int.max 0 new_index in
    let overflow = new_index = List.length children - 1 in
    let new_index = Int.min (List.length children - 1) new_index in
    let next = List.nth children new_index in
    let> () =
      Undoable.Browser.set_class "slipshow__carousel_active" true next
    in
    let> () =
      current_index |> Option.to_list
      |> Undoable.List.iter (fun (old_index, active_elem) ->
             if old_index <> new_index then
               Undoable.Browser.set_class "slipshow__carousel_active" false
                 active_elem
             else Undoable.return ())
    in
    Undoable.return (Some overflow)

  let do_js ~mode _window js_args =
    let> _ = do_js' ~mode _window js_args in
    Undoable.return ()

  (* TODO: Make it more elegant, coding-wise! *)
  let do_1 ~mode window elem ({ target; n; _ } as arg) =
    let< target_elem =
      elem_of_id_or_self target elem ~none:(Undoable.return None)
    in
    check_carousel target_elem @@ fun () ->
    let> new_n =
      match n with
      | [] -> Undoable.return []
      | change :: rest -> (
          let> overflow = do_js' ~mode window { elem = target_elem; change } in
          match overflow with
          | None -> Undoable.return []
          | Some overflow -> (
              match change with
              | All when not overflow -> Undoable.return n
              | Range (a, b) when a < b ->
                  Undoable.return (Range (a + 1, b) :: rest)
              | Range (a, b) when a = b -> Undoable.return rest
              | Range (a, b) (* when a > b *) ->
                  Undoable.return (Range (a - 1, b) :: rest)
              | _ -> Undoable.return rest))
    in
    Undoable.return
    @@ match new_n with [] -> None | new_n -> Some { arg with n = new_n }

  let do_ ~mode _window elem args =
    let> args = Undoable.List.filter_map (do_1 ~mode _window elem) args in
    match args with
    | [] -> Undoable.return ()
    | args ->
        let new_v = args_as_string args in
        Undoable.Browser.set_at on (Some (Jstr.v new_v)) elem

  let setup = None
  let setup_all = None
end

module _ : S = Change_page

module Draw = struct
  include Actions_arguments.Draw

  let state = Hashtbl.create 10

  let setup elem =
    match Hashtbl.find_opt state elem with
    | Some _ -> Fut.return ()
    | None ->
        let data = El.at (Jstr.v "x-data") elem in
        (match data with
        | None -> ()
        | Some data -> (
            let open Drawing_state in
            match
              Drawing_state.Json.string_to_recording (Jstr.to_string data)
            with
            | Error e -> Console.(log [ e ])
            | Ok recording ->
                let replaying_state =
                  { recording; time = Lwd.var 0.; is_playing = Lwd.var false }
                in
                Hashtbl.add state elem replaying_state;
                Lwd_table.append' workspaces.recordings replaying_state));
        Fut.return ()

  let setup_all () =
    El.fold_find_by_selector
      (fun elem acc -> Fut.bind acc (fun () -> setup elem))
      (Jstr.v ".slipshow-hand-drawn")
      (Fut.return ())

  let setup_all = Some setup_all

  let setup el args =
    let elems = elems_of_ids_or_self args el in
    List.fold_left
      (fun acc elem -> Fut.bind acc (fun () -> setup elem))
      (Fut.return ()) elems

  let setup = Some setup

  let replay ?(speedup = 1.) mode (record : Drawing_state.replaying_state) =
    let fut, resolve_fut = Fut.create () in
    let start_replay = Drawing_controller.Tools.now () in
    let original_time = Lwd.peek record.time in
    let max_time = Lwd.peek record.recording.total_time in
    let current_time = ref @@ Drawing_controller.Tools.now () in
    let rec draw_loop _ =
      let when_slow () =
        let now = Drawing_controller.Tools.now () in
        let increment = now -. !current_time in
        current_time := now;
        let before = now -. increment in
        let new_time = original_time +. ((now -. start_replay) *. speedup) in
        let time_before =
          original_time +. ((before -. start_replay) *. speedup)
        in
        let has_crossed_pause =
          Lwd_table.fold
            (fun b (pause : Drawing_state.pause) ->
              b
              ||
              let at = Lwd.peek pause.p_at in
              time_before <= at && at < new_time)
            false record.recording.pauses
        in
        Lwd.set record.time new_time;
        if has_crossed_pause then resolve_fut ()
        else if new_time >= max_time then (
          Lwd.set record.time max_time;
          resolve_fut ())
        else
          let _animation_frame_id = G.request_animation_frame draw_loop in
          ()
      in
      match mode with
      | Fast.Slow -> when_slow ()
      | Fast.Normal hurry_bomb when not (Fast.has_detonated hurry_bomb) ->
          when_slow ()
      | _ ->
          let now = Drawing_controller.Tools.now () in
          let increment = now -. !current_time in
          current_time := now;
          let before = now -. increment in
          let time_before =
            original_time +. ((before -. start_replay) *. speedup)
          in
          let next_time =
            Lwd_table.fold
              (fun acc (pause : Drawing_state.pause) ->
                let at = Lwd.peek pause.p_at in
                if at < time_before then acc
                else Float.min acc (Float.next_after at (at +. 1.)))
              (Lwd.peek record.recording.total_time)
              record.recording.pauses
          in
          Lwd.set record.time next_time;
          resolve_fut ()
      (* | Counting_for_toc -> assert false (\* See "only_if_not_fast" *\) *)
    in
    let _animation_frame_id = G.request_animation_frame draw_loop in
    fut

  type js_args = El.t list

  let do_js ~mode _window elems =
    only_if_not_counting mode @@ fun _mode ->
    (* let speedup = update_speedup 1. in *)
    Undoable.List.iter
      (fun elem ->
        match Hashtbl.find_opt state elem with
        | None -> Undoable.return ()
        | Some record ->
            let open Fut.Syntax in
            let old_time = Lwd.peek record.time in
            let* () = replay ?speedup:None mode record in
            let undo () =
              Lwd.set record.time old_time;
              Fut.return ()
            in
            Undoable.return ~undo ())
      elems

  let do_ ~mode _window el args =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self args el in
    do_js ~mode _window elems
end

module _ : S = Draw

module Clear_draw = struct
  include Actions_arguments.Clear_draw

  let setup = None
  let setup_all = None

  type js_args = El.t list

  let do_js ~mode _window elems =
    only_if_not_counting mode @@ fun _mode ->
    Undoable.List.iter
      (fun elem ->
        match Hashtbl.find_opt Draw.state elem with
        | None -> Undoable.return ()
        | Some record ->
            let old_time = Lwd.peek record.time in
            Lwd.set record.time 0.;
            let undo () =
              Lwd.set record.time old_time;
              Fut.return ()
            in
            Undoable.return ~undo ())
      elems

  let do_ ~mode _window el args =
    only_if_not_counting mode @@ fun _mode ->
    let elems = elems_of_ids_or_self args el in
    do_js ~mode _window elems
end

module _ : S = Clear_draw
