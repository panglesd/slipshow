open Undoable.Syntax

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

  let delay = ("delay", Float.of_string)
  let margin = ("margin", Float.of_string)
end

module Pause = struct
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

  type args = Brr.El.t

  let parse_args elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x = Parse.parse ~named:[] ~positional:Parse.id s in
    match Parse.merge_positional x with
    | [] -> [ elem ]
    | x -> List.filter_map Brr.El.find_first_by_selector x

  let do_ elem =
    let> () = set_class "pauseTarget" false elem in
    update elem (fun n -> n - 1)
end

module Move (X : sig
  val action_name : string

  val move :
    ?delay:float ->
    ?margin:float ->
    Universe.Window.t ->
    Brr.El.t ->
    unit Undoable.t
end) =
struct
  type args = { margin : float option; delay : float option; elem : Brr.El.t }

  let parse_args elem s =
    let ( let* ) = Result.bind in
    let* x =
      Parse.parse ~named:[ Parse.delay; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name:X.action_name x with
    | [ delay; margin ], positional -> (
        match
          Parse.require_single_positional ~action_name:X.action_name positional
        with
        | None -> Ok { elem; delay; margin }
        | Some positional -> (
            match Brr.El.find_first_by_selector positional with
            | None ->
                Error
                  (`Msg
                     ("Could not find element with id"
                    ^ Jstr.to_string positional))
            | Some elem -> Ok { elem; delay; margin }))

  let do_ window { margin; delay; elem } =
    let margin = Option.value ~default:0. margin in
    let delay = Option.value ~default:1. delay in
    X.move ~margin ~delay window elem
end

module Up = Move (struct
  let action_name = "up"
  let move = Universe.Move.up
end)

module Down = Move (struct
  let action_name = "down"
  let move = Universe.Move.down
end)

module Center = Move (struct
  let action_name = "center"
  let move = Universe.Move.center
end)

module Scroll = Move (struct
  let action_name = "scroll"
  let move = Universe.Move.scroll
end)

module Enter = struct
  type t = { elem : Brr.El.t; coord : Universe.Coordinates.window }

  let stack = Stack.create ()

  let in_ elem =
    Undoable.Stack.push { elem; coord = Universe.State.get_coord () } stack
end

let enter window elem =
  let> () = Enter.in_ elem in
  Universe.Move.enter window elem

let exit window to_elem =
  let rec exit () =
    let coord = Undoable.Stack.peek Enter.stack in
    match coord with
    | None -> Undoable.return ()
    | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
        Undoable.return ()
    | Some { coord; _ } -> (
        let> _ = Undoable.Stack.pop_opt Enter.stack in
        match Undoable.Stack.peek Enter.stack with
        | None -> Universe.Move.move window coord ~delay:1.0
        | Some { Enter.elem; _ } when Brr.El.contains elem ~child:to_elem ->
            Universe.Move.move window coord ~delay:1.0
        | Some _ -> exit ())
  in
  exit ()

let unstatic elems =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" true) elems

let static elem =
  Undoable.List.iter (Undoable.Browser.set_class "unstatic" false) elem

module Focus = struct
  type args = {
    margin : float option;
    delay : float option;
    elems : Brr.El.t list;
  }

  let action_name = "focus"

  let parse_args elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x =
      Parse.parse ~named:[ Parse.delay; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name x with
    | [ delay; margin ], [] -> { elems = [ elem ]; delay; margin }
    | [ delay; margin ], positional ->
        let elems = List.filter_map Brr.El.find_first_by_selector positional in
        { elems; delay; margin }

  let do_ window { margin; delay; elems } =
    let> () = State.Focus.push (Universe.State.get_coord ()) in
    let margin = Option.value ~default:0. margin in
    let delay = Option.value ~default:1. delay in
    Universe.Move.focus ~margin ~delay window elems
end

let unfocus window () =
  let> coord = State.Focus.pop () in
  match coord with
  | None -> Undoable.return ()
  | Some coord -> Universe.Move.move window coord ~delay:1.0

let reveal elem =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" false) elem

let unreveal elems =
  Undoable.List.iter (Undoable.Browser.set_class "unrevealed" true) elems

let emph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" true) elems

let unemph elems =
  Undoable.List.iter (Undoable.Browser.set_class "emphasized" false) elems

module type S = sig
  type args

  val parse_args : Brr.El.t -> string -> (args, [> `Msg of string ]) result
  val do_ : Universe.Window.t -> args -> unit Undoable.t
end

module type Move = sig
  type args = { margin : float option; delay : float option; elem : Brr.El.t }

  include S with type args := args
end
