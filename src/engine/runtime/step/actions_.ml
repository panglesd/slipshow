open Undoable.Syntax

(** On an invalid selector, this function will raise. Since in this module ids
    are user input, we valide them *)
let find_first_by_selector ?root x =
  try Brr.El.find_first_by_selector ?root x
  with e ->
    Brr.Console.(error [ e ]);
    None

(* We define the [Actions_] module to avoid a circular dependency: If we had
   only one [Action] module (and not an [Actions] and an [Actions_]) then
   [Actions] would depend on [Javascrip_api] which would depend on [Actions]. *)

module Parse : sig
  val id : string -> Jstr.t

  type 'a description_named_atom =
    string * (string -> ('a, [ `Msg of string ]) result)

  type _ descr_tuple =
    | [] : unit descr_tuple
    | ( :: ) :
        'a description_named_atom * 'b descr_tuple
        -> ('a * 'b) descr_tuple

  type _ output_tuple =
    | [] : unit output_tuple
    | ( :: ) : 'a option * 'b output_tuple -> ('a * 'b) output_tuple

  type 'a non_empty_list = 'a * 'a list

  type ('named, 'positional) parsed = {
    p_named : 'named output_tuple;
    p_pos : 'positional list;
  }

  val parse :
    named:'named descr_tuple ->
    positional:(string -> 'pos) ->
    string ->
    (('named, 'pos) parsed non_empty_list, [> `Msg of string ]) result

  val merge_positional : (unit, 'a) parsed * (unit, 'a) parsed list -> 'a list
  val require_single_action : action_name:string -> 'a * 'b list -> 'a
  val require_single_positional : action_name:string -> 'a list -> 'a option

  val no_args :
    action_name:string -> 'a -> string -> (unit, [> `Msg of string ]) result

  val parse_only_els :
    Brr.El.t -> string -> (Brr.El.t list, [> `Msg of string ]) result

  val parse_only_el :
    Brr.El.t -> string -> (Brr.El.t, [> `Msg of string ]) result

  val option_to_error : 'a -> 'b option -> ('b, [> `Msg of 'a ]) result
  val duration : string * (string -> (float, [> `Msg of string ]) result)
  val margin : string * (string -> (float, [> `Msg of string ]) result)
end = struct
  let parse_string s =
    let is_ws idx = match s.[idx] with '\n' | ' ' -> true | _ -> false in
    let is_alpha idx =
      let c = s.[idx] in
      ('a' <= c && c <= 'z')
      || ('A' <= c && c <= 'Z')
      || ('0' <= c && c <= '9')
      || c = '_'
    in
    let rec consume_ws idx =
      if idx >= String.length s then idx
      else if is_ws idx then consume_ws (idx + 1)
      else idx
    in
    let rec consume_non_ws idx =
      if idx >= String.length s then idx
      else if not (is_ws idx) then consume_non_ws (idx + 1)
      else idx
    in
    let rec consume_alpha idx =
      if idx >= String.length s then idx
      else if is_alpha idx then consume_alpha (idx + 1)
      else idx
    in
    let quoted_string idx =
      let rec take_inside_quoted_string acc idx =
        match s.[idx] with
        | '"' -> (acc |> List.rev |> List.to_seq |> String.of_seq, idx + 1)
        | '\\' -> take_inside_quoted_string (s.[idx + 1] :: acc) (idx + 2)
        | _ -> take_inside_quoted_string (s.[idx] :: acc) (idx + 1)
      in
      take_inside_quoted_string [] idx
    in
    let parse_unquoted_string idx =
      let idx0 = idx in
      let idx = consume_non_ws idx in
      let arg = String.sub s idx0 (idx - idx0) in
      (arg, idx)
    in
    let parse_arg idx =
      match s.[idx] with
      | '"' -> quoted_string (idx + 1)
      | _ -> parse_unquoted_string idx
    in
    let repeat parser idx =
      let rec do_ acc idx =
        match parser idx with
        | None -> (List.rev acc, idx)
        | Some (x, idx') ->
            if idx' = idx then
              failwith "Parser did not consume input; infinite loop detected"
            else do_ (x :: acc) idx'
      in
      do_ [] idx
    in
    let parse_name idx =
      let idx0 = idx in
      let idx = consume_alpha idx in
      let name = String.sub s idx0 (idx - idx0) in
      (name, idx)
    in
    let parse_column idx =
      match s.[idx] with
      | ':' -> idx + 1
      | _ -> failwith "no : after named argument"
    in
    let parse_named idx =
      let idx = consume_ws idx in
      match s.[idx] with
      | '~' ->
          let idx = idx + 1 in
          let name, idx = parse_name idx in
          let idx = parse_column idx in
          let arg, idx = parse_arg idx in
          Some ((name, arg), idx)
      | (exception Invalid_argument _) | _ -> None
    in
    let parse_semicolon idx =
      let idx = consume_ws idx in
      match s.[idx] with
      | ';' -> Some ((), idx + 1)
      | (exception Invalid_argument _) | _ -> None
    in
    let parse_positional idx =
      let idx = consume_ws idx in
      match s.[idx] with
      | _ -> Some (parse_arg idx)
      | exception Invalid_argument _ -> None
    in
    let parse_one idx =
      let ( let$ ) x f = match x with Some _ as x -> x | None -> f () in
      let ( let> ) x f =
        match x with Some (x, idx) -> Some (f x, idx) | None -> None
      in
      let$ () =
        let> named = parse_named idx in
        `Named named
      in
      let$ () =
        let> () = parse_semicolon idx in
        `Semicolon
      in
      let> p = parse_positional idx in
      `Positional p
    in
    let parse_all = repeat parse_one in
    let parsed, _ = parse_all 0 in
    let unfinished_acc, parsed =
      List.fold_left
        (fun (current_acc, global_acc) -> function
          | `Semicolon -> ([], List.rev current_acc :: global_acc)
          | (`Positional _ | `Named _) as x -> (x :: current_acc, global_acc))
        ([], []) parsed
    in
    let parsed = List.rev unfinished_acc :: parsed |> List.rev in
    parsed
    |> List.map
       @@ List.partition_map (function
            | `Named x -> Left x
            | `Positional p -> Right p)

  let ( let+ ) x y = Result.map y x

  module Smap_ = Map.Make (String)

  module Smap = struct
    include Smap_

    (* of_list has only been added in 5.1. Implementation taken from the OCaml
       stdlib. *)
    let of_list bs = List.fold_left (fun m (k, v) -> add k v m) empty bs
  end

  type action = { named : string Smap.t; positional : string list }

  let parse_string s =
    let+ s =
      try Ok (parse_string s)
      with _ (* TODO: finer grain catch and better error messages *) ->
        Error (`Msg "Failed when trying to parse argument")
    in
    s
    |> List.map (fun (named, positional) ->
           let named =
             Smap.of_list named
             (* TODO: warn on duplicate name *)
           in
           { named; positional })

  let id x = Jstr.of_string ("#" ^ x)

  type 'a description_named_atom =
    string * (string -> ('a, [ `Msg of string ]) result)

  type _ descr_tuple =
    | [] : unit descr_tuple
    | ( :: ) :
        'a description_named_atom * 'b descr_tuple
        -> ('a * 'b) descr_tuple

  type _ output_tuple =
    | [] : unit output_tuple
    | ( :: ) : 'a option * 'b output_tuple -> ('a * 'b) output_tuple

  type 'a non_empty_list = 'a * 'a list

  type ('named, 'positional) parsed = {
    p_named : 'named output_tuple;
    p_pos : 'positional list;
  }

  let parsed_name (description_name, description_convert) action =
    Smap.find_opt description_name action.named
    |> Option.map description_convert

  let rec parsed_names : type a. action -> a descr_tuple -> a output_tuple =
   fun action descriptions ->
    match descriptions with
    | [] -> []
    | description :: rest ->
        let parsed =
          match parsed_name description action with
          | None -> None
          | Some (Error (`Msg s)) ->
              Logs.warn (fun m -> m "Could not parse argument: %s" s);
              None
          | Some (Ok a) -> Some a
        in
        parsed :: parsed_names action rest

  let parse_atom ~named ~positional action =
    let p_named = parsed_names action named in
    let p_pos = List.map positional action.positional in
    { p_named; p_pos }

  let parse ~named ~positional s :
      (('named, 'pos) parsed non_empty_list, _) result =
    let+ parsed_string = parse_string s in
    List.map (parse_atom ~named ~positional) parsed_string |> function
    | [] ->
        assert false
        (* An empty string would be parsed as [ [[None; None; ...], []] ] *)
    | a :: rest -> ((a, rest) : _ non_empty_list)

  let merge_positional (h, t) =
    List.concat_map
      (fun { p_named = ([] : _ output_tuple); p_pos = p } -> p)
      (h :: t)

  let require_single_action ~action_name x =
    match x with
    | a, rest ->
        let () =
          match (rest : _ list) with
          | [] -> ()
          | _ :: _ ->
              Logs.warn (fun m ->
                  m "Action %s does not support ';'-separated arguments"
                    action_name)
        in
        a

  let require_single_positional ~action_name (x : _ list) =
    match x with
    | [] -> None
    | a :: rest ->
        let () =
          match rest with
          | [] -> ()
          | _ :: _ ->
              Logs.warn (fun m ->
                  m "Action %s does not support multiple arguments" action_name)
        in
        Some a

  let no_args ~action_name _elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x = parse ~named:[] ~positional:id s in
    match x with
    | { p_named = []; p_pos = [] }, [] -> ()
    | _ ->
        Logs.warn (fun m ->
            m "The %s action does not accept any argument" action_name)

  let parse_only_els elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x = parse ~named:[] ~positional:id s in
    match merge_positional x with
    | [] -> List.[ elem ]
    | x -> List.filter_map find_first_by_selector x

  let parse_only_el elem s =
    let ( let$ ) = Result.bind in
    let$ x = parse ~named:[] ~positional:id s in
    match merge_positional x with
    | [] -> Ok elem
    | _ :: _ :: _ -> Error (`Msg "Expected a single ID")
    | [ x ] -> (
        match find_first_by_selector x with
        | Some x -> Ok x
        | None ->
            Error (`Msg ("Could not find element with ID " ^ Jstr.to_string x)))

  let option_to_error error = function
    | Some x -> Ok x
    | None -> Error (`Msg error)

  let duration =
    ( "duration",
      fun x ->
        x |> Float.of_string_opt |> option_to_error "Error during float parsing"
    )

  let margin =
    ( "margin",
      fun x ->
        x |> Float.of_string_opt |> option_to_error "Error during float parsing"
    )
end

module type S = sig
  type args

  val setup : (args -> unit Fut.t) option
  val on : string
  val action_name : string
  val parse_args : Brr.El.t -> string -> (args, [> `Msg of string ]) result
  val do_ : Universe.Window.t -> args -> unit Undoable.t
end

module type Move = sig
  type args = {
    margin : float option;
    duration : float option;
    elem : Brr.El.t;
  }

  include S with type args := args
end

module type SetClass = S with type args = Brr.El.t list

let only_if_not_fast f =
  if Fast.is_counting () then Undoable.return () else f ()

module Pause = struct
  let on = "pause"
  let action_name = "pause"

  let do_to_root elem f =
    let is_root elem =
      Brr.El.class' (Jstr.v "slip") elem
      || Brr.El.class' (Jstr.v "slide") elem
      || Brr.El.class' (Jstr.v "slipshow-universe") elem
      || (Option.is_some @@ Brr.El.at (Jstr.v "pause-block") elem)
    in
    let rec do_rec elem =
      if is_root elem then Undoable.return ()
      else
        let> () = f elem in
        match Brr.El.parent elem with
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
      match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
      | None -> 0
      | Some n -> (
          match Jstr.to_int n with
          | None ->
              Brr.Console.(
                log [ "Error: wrong value to pauseAncestorMultiplicity:"; n ]);
              0
          | Some n -> n)
    in
    update_single elem (f n)

  let setup elem =
    let> () = set_class "pauseTarget" true elem in
    update elem (( + ) 1)

  let setup elems = Undoable.List.iter setup elems |> Undoable.discard
  let setup = Some setup

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let do_ _window elems =
    only_if_not_fast @@ fun () ->
    elems
    |> Undoable.List.iter @@ fun elem ->
       let> () = set_class "pauseTarget" false elem in
       update elem (fun n -> n - 1)
end

module Move (X : sig
  val on : string
  val action_name : string

  val move :
    ?duration:float ->
    ?margin:float ->
    Universe.Window.t ->
    Brr.El.t ->
    unit Undoable.t
end) =
struct
  let on = X.on
  let action_name = X.action_name
  let setup = None

  type args = {
    margin : float option;
    duration : float option;
    elem : Brr.El.t;
  }

  let parse_args elem s =
    let ( let* ) = Result.bind in
    let* x =
      Parse.parse ~named:[ Parse.duration; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name:X.action_name x with
    | { p_named = [ duration; margin ]; p_pos = positional } -> (
        match
          Parse.require_single_positional ~action_name:X.action_name positional
        with
        | None -> Ok { elem; duration; margin }
        | Some positional -> (
            match find_first_by_selector positional with
            | None ->
                Error
                  (`Msg
                     ("Could not find element with id"
                    ^ Jstr.to_string positional))
            | Some elem -> Ok { elem; duration; margin }))

  let do_ window { margin; duration; elem } =
    only_if_not_fast @@ fun () ->
    let margin = Option.value ~default:0. margin in
    let duration = Option.value ~default:1. duration in
    X.move ~margin ~duration window elem
end

module SetClass (X : sig
  val on : string
  val action_name : string
  val class_ : string
  val state : bool
end) =
struct
  let on = X.on
  let action_name = X.action_name
  let setup = None

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let do_ _window elems =
    only_if_not_fast @@ fun () ->
    Undoable.List.iter (Undoable.Browser.set_class X.class_ X.state) elems
end

module Up = Move (struct
  let on = "up-at-unpause"
  let action_name = "up"
  let move = Universe.Move.up
end)

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
    element_entered : Brr.El.t;  (** The element we entered *)
    coord_left : Universe.Coordinates.window;
        (** The coordinate we left when entering *)
    duration : float option;  (** The duration it took to enter entering *)
  }

  let stack = Stack.create ()

  include Move (struct
    let on = "enter-at-unpause"
    let action_name = "enter"

    let move ?duration ?margin window element_entered =
      let> () =
        let coord_left = Universe.State.get_coord () in
        Undoable.Stack.push { element_entered; coord_left; duration } stack
      in
      Universe.Move.enter ?duration ?margin window element_entered
  end)
end

let exit window to_elem =
  let rec exit () =
    let coord = Undoable.Stack.peek Enter.stack in
    match coord with
    | None -> Undoable.return ()
    | Some { element_entered; _ }
      when Brr.El.contains element_entered ~child:to_elem ->
        Undoable.return ()
    | Some { coord_left; duration; _ } -> (
        let duration = Option.value duration ~default:1.0 in
        let> _ = Undoable.Stack.pop_opt Enter.stack in
        match Undoable.Stack.peek Enter.stack with
        | None -> Universe.Move.move window coord_left ~duration
        | Some { Enter.element_entered; _ }
          when Brr.El.contains element_entered ~child:to_elem ->
            let duration =
              match Brr.El.at (Jstr.v "enter-at-unpause") to_elem with
              | None -> duration
              | Some s -> (
                  match Enter.parse_args to_elem (Jstr.to_string s) with
                  | Error _ -> duration
                  | Ok v -> Option.value ~default:duration v.duration)
            in
            Universe.Move.move window coord_left ~duration
        | Some _ -> exit ())
  in
  exit ()

module Unstatic = SetClass (struct
  let on = "unstatic-at-unpause"
  let action_name = "unstatic"
  let class_ = "unstatic"
  let state = true
end)

module Static = SetClass (struct
  let on = "static-at-unpause"
  let action_name = "static"
  let class_ = "unstatic"
  let state = false
end)

module Focus = struct
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

  type args = {
    margin : float option;
    duration : float option;
    elems : Brr.El.t list;
  }

  let on = "focus-at-unpause"
  let action_name = "focus"

  let parse_args elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x =
      Parse.parse ~named:[ Parse.duration; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name x with
    | { p_named = [ duration; margin ]; p_pos = [] } ->
        { elems = [ elem ]; duration; margin }
    | { p_named = [ duration; margin ]; p_pos = positional } ->
        let elems = List.filter_map find_first_by_selector positional in
        { elems; duration; margin }

  let do_ window { margin; duration; elems } =
    only_if_not_fast @@ fun () ->
    let> () = State.push (Universe.State.get_coord ()) in
    let margin = Option.value ~default:0. margin in
    let duration = Option.value ~default:1. duration in
    Universe.Move.focus ~margin ~duration window elems

  let setup = None
end

module Unfocus = struct
  type args = unit

  let setup = None
  let on = "unfocus-at-unpause"
  let action_name = "unfocus"
  let parse_args elem s = Parse.no_args ~action_name elem s

  let do_ window () =
    only_if_not_fast @@ fun () ->
    let> coord = Focus.State.pop () in
    match coord with
    | None -> Undoable.return ()
    | Some coord -> Universe.Move.move window coord ~duration:1.0
end

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
  type args = unit

  let setup = None
  let on = "step"
  let action_name = "step"
  let parse_args elem s = Parse.no_args ~action_name elem s
  let do_ _ _ = Undoable.return ()
end

module Speaker_note : S = struct
  let on = "speaker-note"
  let action_name = on

  type args = Brr.El.t

  let parse_args = Parse.parse_only_el
  let sn = ref ""

  let setup elem =
    Fut.return @@ Brr.El.set_class (Jstr.v "__slipshow__speaker_note") true elem

  let setup = Some setup

  let do_ (_ : Universe.Window.t) (el : args) =
    let innerHTML =
      Jv.Jstr.get (Brr.El.to_jv el) "innerHTML" |> Jstr.to_string
    in
    let old_value = !sn in
    let undo () =
      Messaging.send_speaker_notes old_value;
      sn := old_value;
      Fut.return ()
    in
    sn := innerHTML;
    Messaging.send_speaker_notes !sn;
    Undoable.return ~undo ()
end

module Play_media = struct
  let on = "play-media"
  let action_name = "play-media"

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els
  let log_error = function Ok x -> x | Error x -> Brr.Console.(log [ x ])

  let do_ _window elems =
    only_if_not_fast @@ fun () ->
    let is_speaker_note =
      match Brr.Window.name Brr.G.window |> Jstr.to_string with
      | "slipshow_speaker_view" -> true
      | _ -> false
    in
    Undoable.List.iter
      (fun e ->
        let open Fut.Syntax in
        let is_video = Jstr.equal (Jstr.v "video") @@ Brr.El.tag_name e in
        let is_audio = Jstr.equal (Jstr.v "audio") @@ Brr.El.tag_name e in
        if (not is_video) && not is_audio then (
          Brr.Console.(
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
          let is_playing = not @@ Brr_io.Media.El.paused e in
          let undo () =
            let+ res =
              if is_playing then Brr_io.Media.El.play e
              else Fut.return (Ok (Brr_io.Media.El.pause e))
            in
            log_error res;
            Brr_io.Media.El.set_current_time_s e current
          in
          let* res =
            let open Brr_io.Media.El in
            if Fast.is_fast () then (
              Brr.Console.(log [ "Just setting current time" ]);
              Fut.return @@ Ok (set_current_time_s e (duration_s e)))
            else (
              Brr.Console.(log [ "Playing" ]);
              Brr_io.Media.El.play e)
          in
          log_error res;
          Undoable.return ~undo ())
      elems

  let setup = None
end

module Change_page = struct
  type change = Absolute of int | Relative of int | All | Range of int * int

  type arg = {
    target_elem : Brr.El.t;
    n : change list;
    original_id : string option;
  }

  type args = { original_elem : Brr.El.t; args : arg list }

  let on = "change-page"
  let action_name = "change-page"
  let ( let+ ) x f = Result.map f x
  let ( let* ) x f = Result.bind x f

  let handle_error = function
    | Ok x -> Some x
    | Error (`Msg x) ->
        Brr.Console.(log [ x ]);
        None

  let parse_change s =
    if String.equal "all" s then Some All
    else
      match int_of_string_opt s with
      | None -> (
          match String.split_on_char '-' s with
          | [ a; b ] -> (
              match (int_of_string_opt a, int_of_string_opt b) with
              | Some a, Some b -> Some (Range (a, b))
              | _ ->
                  Brr.Console.(log [ "Could not parse parameter" ]);
                  None)
          | _ ->
              Brr.Console.(log [ "Could not parse parameter" ]);
              None)
      | Some x -> (
          match s.[0] with
          | '+' | '-' -> Some (Relative x)
          | _ -> Some (Absolute x))

  let parse_single_action original_elem
      { Parse.p_named = ([ n_opt ] : _ Parse.output_tuple); p_pos = elem_ids } =
    let n = Option.value ~default:[ Relative 1 ] n_opt in
    let+ elem, elem_id =
      match elem_ids with
      | [] -> Ok (original_elem, None)
      | [ id ] -> (
          find_first_by_selector ("#" ^ id |> Jstr.v) |> function
          | Some x -> Ok (x, Some id)
          | None -> Error (`Msg "No elem of id found"))
      | id :: _ -> (
          Brr.Console.(log [ "Expected single id" ]);
          find_first_by_selector ("#" ^ id |> Jstr.v) |> function
          | Some x -> Ok (x, Some id)
          | None -> Error (`Msg "No elem of id found"))
    in
    { n; target_elem = elem; original_id = elem_id }

  let parse_n s =
    let l =
      String.split_on_char ' ' s
      |> List.filter (fun x -> not @@ String.equal "" x)
    in
    l |> List.filter_map parse_change |> Result.ok

  let parse_args original_elem s =
    let+ ac, actions =
      Parse.parse ~named:[ ("n", parse_n) ] ~positional:Fun.id s
    in
    let actions = ac :: actions in
    let args =
      List.filter_map
        (fun action -> parse_single_action original_elem action |> handle_error)
        actions
    in
    { args; original_elem }

  let args_as_string args =
    let arg_to_string { n; original_id; _ } =
      let to_string = function
        | All -> "all"
        | Relative x when x < 0 -> string_of_int x
        | Relative x -> "+" ^ string_of_int x
        | Absolute x -> string_of_int x
        | Range (x, y) -> string_of_int x ^ "-" ^ string_of_int y
      in
      let s = n |> List.map to_string |> String.concat " " in
      let n = "~n:\"" ^ s ^ "\"" in
      let original_id =
        match original_id with None -> "" | Some s -> " " ^ s
      in
      n ^ original_id
    in
    args |> List.map arg_to_string |> String.concat " ; "

  (* Taken from OCaml 5.2 *)
  let find_mapi f =
    let rec aux i = function
      | [] -> None
      | x :: l -> (
          match f i x with Some _ as result -> result | None -> aux (i + 1) l)
    in
    aux 0

  let do_1 ({ target_elem; n; _ } as arg) =
    let check_carousel f =
      if Brr.El.class' (Jstr.v "slipshow__carousel") target_elem then f ()
      else Undoable.return None
    in
    check_carousel @@ fun () ->
    let children = Brr.El.children ~only_els:true target_elem in
    let current_index =
      find_mapi
        (fun i x ->
          if Brr.El.class' (Jstr.v "slipshow__carousel_active") x then
            Some (i, x)
          else None)
        children
    in
    let new_index =
      match (n, current_index) with
      | Range (a, _) :: _, _ -> a
      | Absolute i :: _, _ -> i - 1
      | Relative r :: _, Some (i, _) -> i + r
      | All :: _, Some (i, _) -> i + 1
      | _ ->
          Brr.Console.(log [ "Error during carousel" ]);
          0
    in
    let new_index = Int.max 0 new_index in
    let overflow = new_index = List.length children - 1 in
    let new_index = Int.min (List.length children - 1) new_index in
    let next = List.nth children new_index in
    let> () =
      current_index |> Option.to_list
      |> Undoable.List.iter (fun (_, active_elem) ->
             Undoable.Browser.set_class "slipshow__carousel_active" false
               active_elem)
    in
    let> () =
      Undoable.Browser.set_class "slipshow__carousel_active" true next
    in
    let new_n =
      match n with
      | [] -> []
      | All :: _ as n when not overflow -> n
      | Range (a, b) :: rest when a < b -> Range (a + 1, b) :: rest
      | Range (a, b) :: rest when a = b -> rest
      | Range (a, b) :: rest (* when a > b *) -> Range (a - 1, b) :: rest
      | _ :: n -> n
    in
    Undoable.return
    @@ match new_n with [] -> None | new_n -> Some { arg with n = new_n }

  let do_ _window { args; original_elem } =
    let> args = Undoable.List.filter_map do_1 args in
    match args with
    | [] -> Undoable.return ()
    | args ->
        let new_v = args_as_string args in
        Undoable.Browser.set_at on (Some (Jstr.v new_v)) original_elem

  let do_javascript_api ~target_elem ~change =
    let> _ = do_1 { target_elem; n = [ change ]; original_id = None } in
    Undoable.return ()

  let setup = None
end

module Draw = struct
  let state = Hashtbl.create 10
  let on = "draw"
  let action_name = on

  let setup elem =
    let data = Brr.El.at (Jstr.v "x-data") elem in
    (match data with
    | None -> ()
    | Some data -> (
        let open Drawing_state.Live_coding in
        match Drawing_state.Json.string_to_recording (Jstr.to_string data) with
        | Error e -> Brr.Console.(log [ e ])
        | Ok recording ->
            let replaying_state = { recording; time = Lwd.var 0. } in
            Hashtbl.add state elem replaying_state;
            Lwd_table.append' Drawing_state.Live_coding.workspaces.recordings
              replaying_state));
    Fut.return ()

  let setup elems =
    List.fold_left
      (fun acc elem -> Fut.bind acc (fun () -> setup elem))
      (Fut.return ()) elems

  let setup = Some setup

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let update_speedup speedup =
    match Fast.get_mode () with
    | Normal -> speedup
    | Fast_move -> 10000.
    | Counting_for_toc -> assert false (* See "only_if_not_fast" *)

  let replay ?(speedup = 1.)
      (record : Drawing_state.Live_coding.replaying_state) =
    let fut, resolve_fut = Fut.create () in
    let start_replay = Drawing_controller.Tools.now () in
    let original_time = Lwd.peek record.time in
    let max_time = Lwd.peek record.recording.total_time in
    let rec draw_loop _ =
      let speedup = update_speedup speedup in
      let new_time =
        original_time
        +. ((Drawing_controller.Tools.now () -. start_replay) *. speedup)
      in
      if new_time >= max_time then (
        Lwd.set record.time max_time;
        resolve_fut ())
      else (
        Lwd.set record.time new_time;
        let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
        ())
    in
    let _animation_frame_id = Brr.G.request_animation_frame draw_loop in
    fut

  let do_ _window elems =
    only_if_not_fast @@ fun () ->
    let speedup = update_speedup 1. in
    Undoable.List.iter
      (fun elem ->
        match Hashtbl.find_opt state elem with
        | None -> Undoable.return ()
        | Some record ->
            let open Fut.Syntax in
            let* () = replay ~speedup record in
            let undo () =
              Lwd.set record.time 0.;
              Fut.return ()
            in
            Undoable.return ~undo ())
      elems
end

module Clear_draw = struct
  let on = "clear"
  let action_name = on
  let setup = None

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let do_ _window elems =
    only_if_not_fast @@ fun () ->
    Undoable.List.iter
      (fun elem ->
        match Hashtbl.find_opt Draw.state elem with
        | None -> Undoable.return ()
        | Some record ->
            let old_time = Lwd.peek record.time in
            Lwd.set record.time (Lwd.peek record.recording.total_time);
            let undo () =
              Lwd.set record.time old_time;
              Fut.return ()
            in
            Undoable.return ~undo ())
      elems
end
