open Undoable.Syntax

(* We define the [Actions_] module to avoid a circular dependency: If we had
   only one [Action] module (and not an [Actions] and an [Actions_]) then
   [Actions] would depend on [Javascrip_api] which would depend on [Actions]. *)

module Parse = struct
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
        | Some (x, idx) -> do_ (x :: acc) idx
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
      | ';' -> Some ((), idx)
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

  module Smap = Map.Make (String)

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

  type 'a description_named_atom = string * (string -> 'a)

  type _ descr_tuple =
    | [] : unit descr_tuple
    | ( :: ) :
        'a description_named_atom * 'b descr_tuple
        -> ('a * 'b) descr_tuple

  type _ output_tuple =
    | [] : unit output_tuple
    | ( :: ) : 'a option * 'b output_tuple -> ('a * 'b) output_tuple

  let parsed_name (description_name, description_convert) action =
    Smap.find_opt description_name action.named
    |> Option.map description_convert

  let rec parsed_names : type a. action -> a descr_tuple -> a output_tuple =
   fun action descriptions ->
    match descriptions with
    | [] -> []
    | description :: rest ->
        parsed_name description action :: parsed_names action rest

  let parse_atom ~named ~positional action =
    let named = parsed_names action named in
    let positional = List.map positional action.positional in
    (named, positional)

  let parse ~named ~positional s =
    let+ parsed_string = parse_string s in
    List.map (parse_atom ~named ~positional) parsed_string |> function
    | [] ->
        assert false
        (* An empty string would be parsed as [ [[None; None; ...], []] ] *)
    | a :: rest -> (a, rest)

  let merge_positional ((([] : _ output_tuple), p), x) =
    p @ List.concat_map (fun (([] : _ output_tuple), p) -> p) x

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
    | ([], []), [] -> ()
    | _ ->
        Logs.warn (fun m ->
            m "The %s action does not accept any argument" action_name)

  let parse_only_els elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x = parse ~named:[] ~positional:id s in
    match merge_positional x with
    | [] -> List.[ elem ]
    | x -> List.filter_map Brr.El.find_first_by_selector x

  let duration = ("duration", Float.of_string)
  let margin = ("margin", Float.of_string)
end

module type S = sig
  type args

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

module Pause = struct
  let on = "pause"
  let action_name = "pause"

  let do_to_root elem f =
    let is_root elem =
      Brr.El.class' (Jstr.v "slip") elem
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

  let setup elems = Undoable.List.iter setup elems

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let do_ _window elems =
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
    | [ duration; margin ], positional -> (
        match
          Parse.require_single_positional ~action_name:X.action_name positional
        with
        | None -> Ok { elem; duration; margin }
        | Some positional -> (
            match Brr.El.find_first_by_selector positional with
            | None ->
                Error
                  (`Msg
                     ("Could not find element with id"
                    ^ Jstr.to_string positional))
            | Some elem -> Ok { elem; duration; margin }))

  let do_ window { margin; duration; elem } =
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

  type args = Brr.El.t list

  let parse_args = Parse.parse_only_els

  let do_ _window elems =
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
    elem : Brr.El.t;
    coord : Universe.Coordinates.window;
    duration : float option;
  }

  let stack = Stack.create ()

  include Move (struct
    let on = "enter-at-unpause"
    let action_name = "enter"

    let move ?duration ?margin window elem =
      let> () =
        Undoable.Stack.push
          { elem; coord = Universe.State.get_coord (); duration }
          stack
      in
      Universe.Move.enter ?duration ?margin window elem
  end)
end

let exit window to_elem =
  let rec exit () =
    let coord = Undoable.Stack.peek Enter.stack in
    match coord with
    | None -> Undoable.return ()
    | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
        Undoable.return ()
    | Some { coord; duration; _ } -> (
        let duration = Option.value duration ~default:1.0 in
        let> _ = Undoable.Stack.pop_opt Enter.stack in
        match Undoable.Stack.peek Enter.stack with
        | None -> Universe.Move.move window coord ~duration
        | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
            if Brr.El.at (Jstr.v "enter-at-unpause") to_elem |> Option.is_some
            then Undoable.return ()
            else Universe.Move.move window coord ~duration:1.0
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
    | [ duration; margin ], [] -> { elems = [ elem ]; duration; margin }
    | [ duration; margin ], positional ->
        let elems = List.filter_map Brr.El.find_first_by_selector positional in
        { elems; duration; margin }

  let do_ window { margin; duration; elems } =
    let> () = State.Focus.push (Universe.State.get_coord ()) in
    let margin = Option.value ~default:0. margin in
    let duration = Option.value ~default:1. duration in
    Universe.Move.focus ~margin ~duration window elems
end

module Unfocus = struct
  type args = unit

  let on = "unfocus-at-unpause"
  let action_name = "unfocus"
  let parse_args elem s = Parse.no_args ~action_name elem s

  let do_ window () =
    let> coord = State.Focus.pop () in
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

  let on = "step"
  let action_name = "step"
  let parse_args elem s = Parse.no_args ~action_name elem s
  let do_ _ _ = Undoable.return ()
end
