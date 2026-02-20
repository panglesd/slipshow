type id_or_self = [ `Self | `Id of string ]
type ids_or_self = [ `Self | `Ids of string list ]

module type S = sig
  type args

  val on : string
  val action_name : string
  val parse_args : string -> (args, [> `Msg of string ]) result
end

module Pause = struct
  let on = "pause"
  let action_name = "pause"

  type args = [ `Self | `Ids of string list ]

  let parse_args = Parse.parse_only_els
end

module _ : S = Pause

module Move (X : sig
  val on : string
  val action_name : string
end) =
struct
  let on = X.on
  let action_name = X.action_name

  type args = {
    margin : float option;
    duration : float option;
    target : id_or_self;
  }

  let parse_args s =
    let ( let* ) = Result.bind in
    let* x =
      Parse.parse ~named:[ Parse.duration; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name:X.action_name x with
    | { p_named = [ duration; margin ]; p_pos = positional } -> (
        match
          Parse.require_single_positional ~action_name:X.action_name positional
        with
        | None -> Ok { target = `Self; duration; margin }
        | Some positional -> Ok { target = `Id positional; duration; margin })
end

(* module Up = Move (struct *)
(*   let on = "up-at-unpause" *)
(*   let action_name = "up" *)
(* end) *)

(* module _ : S = Up *)

(* module Down = Move (struct *)
(*   let on = "down-at-unpause" *)
(*   let action_name = "down" *)
(* end) *)

(* module _ : S = Down *)

(* module Center = Move (struct *)
(*   let on = "center-at-unpause" *)
(*   let action_name = "center" *)
(* end) *)

(* module _ : S = Center *)

(* module Scroll = Move (struct *)
(*   let on = "scroll-at-unpause" *)
(*   let action_name = "scroll" *)
(* end) *)

(* module _ : S = Scroll *)

(* module Enter = Move (struct *)
(*   let on = "enter-at-unpause" *)
(*   let action_name = "enter" *)
(* end) *)

(* module _ : S = Enter *)

module SetClass (X : sig
  val on : string
  val action_name : string
end) =
struct
  let on = X.on
  let action_name = X.action_name

  type args = ids_or_self

  let parse_args = Parse.parse_only_els
end

(* module Unstatic = SetClass (struct *)
(*   let on = "unstatic-at-unpause" *)
(*   let action_name = "unstatic" *)
(* end) *)

(* module _ : S = Unstatic *)

(* module Static = SetClass (struct *)
(*   let on = "static-at-unpause" *)
(*   let action_name = "static" *)
(* end) *)

(* module _ : S = Static *)

(* module Reveal = SetClass (struct *)
(*   let on = "reveal-at-unpause" *)
(*   let action_name = "reveal" *)
(* end) *)

(* module _ : S = Reveal *)

(* module Unreveal = SetClass (struct *)
(*   let on = "unreveal-at-unpause" *)
(*   let action_name = "unreveal" *)
(* end) *)

(* module _ : S = Unreveal *)

(* module Emph = SetClass (struct *)
(*   let on = "emph-at-unpause" *)
(*   let action_name = "emph" *)
(* end) *)

(* module _ : S = Emph *)

(* module Unemph = SetClass (struct *)
(*   let on = "unemph-at-unpause" *)
(*   let action_name = "unemph" *)
(* end) *)

(* module _ : S = Unemph *)

module Step = struct
  type args = unit

  let on = "step"
  let action_name = on
  let parse_args s = Parse.no_args ~action_name s
end

module _ : S = Step

module Focus = struct
  type args = {
    margin : float option;
    duration : float option;
    target : ids_or_self;
  }

  let on = "focus-at-unpause"
  let action_name = "focus"

  let parse_args s =
    let ( let$ ) = Fun.flip Result.map in
    let$ x =
      Parse.parse ~named:[ Parse.duration; Parse.margin ] ~positional:Parse.id s
    in
    match Parse.require_single_action ~action_name x with
    | { p_named = [ duration; margin ]; p_pos = [] } ->
        { target = `Self; duration; margin }
    | { p_named = [ duration; margin ]; p_pos = positional } ->
        let target = `Ids positional in
        { target; duration; margin }
end

module _ : S = Focus

module Unfocus = struct
  type args = unit

  let on = "unfocus-at-unpause"
  let action_name = "unfocus"
  let parse_args s = Parse.no_args ~action_name s
end

module _ : S = Unfocus

module Speaker_note = struct
  let on = "speaker-note"
  let action_name = on

  type args = id_or_self

  let parse_args = Parse.parse_only_el
end

module _ : S = Speaker_note

module Play_media = struct
  let on = "play-media"
  let action_name = "play-media"

  type args = ids_or_self

  let parse_args = Parse.parse_only_els
end

module _ : S = Play_media

module Change_page = struct
  type change = Absolute of int | Relative of int | All | Range of int * int
  type arg = { target : id_or_self; n : change list }
  type args = arg list

  let on = "change-page"
  let action_name = "change-page"
  let ( let+ ) x f = Result.map f x
  let ( let* ) x f = Result.bind x f

  let handle_error = function
    | Ok x -> Some x
    | Error (`Msg _x) ->
        (* TODO: something with [x] *)
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
                  (* TODO: Console.(log [ "Could not parse parameter" ]); *)
                  None)
          | _ ->
              (* TODO: Console.(log [ "Could not parse parameter" ]); *)
              None)
      | Some x -> (
          match s.[0] with
          | '+' | '-' -> Some (Relative x)
          | _ -> Some (Absolute x))

  let parse_single_action
      { Parse.p_named = ([ n_opt ] : _ Parse.output_tuple); p_pos = elem_ids } =
    let n = Option.value ~default:[ Relative 1 ] n_opt in
    let+ id_or_self =
      match elem_ids with
      | [] -> Ok `Self
      | [ id ] -> Ok (`Id id)
      | id :: _ ->
          (* TODO: Console.(log [ "Expected single id" ]); *)
          Ok (`Id id)
    in
    { n; target = id_or_self }

  let parse_n s =
    let l =
      String.split_on_char ' ' s
      |> List.filter (fun x -> not @@ String.equal "" x)
    in
    l |> List.filter_map parse_change |> Result.ok

  let parse_args s =
    let+ ac, actions =
      Parse.parse ~named:[ ("n", parse_n) ] ~positional:Fun.id s
    in
    let actions = ac :: actions in
    let args =
      List.filter_map
        (fun action -> parse_single_action action |> handle_error)
        actions
    in
    args

  let args_as_string args =
    let arg_to_string { n; target } =
      let to_string = function
        | All -> "all"
        | Relative x when x < 0 -> string_of_int x
        | Relative x -> "+" ^ string_of_int x
        | Absolute x -> string_of_int x
        | Range (x, y) -> string_of_int x ^ "-" ^ string_of_int y
      in
      let s = n |> List.map to_string |> String.concat " " in
      let n = "~n:\"" ^ s ^ "\"" in
      let original_id = match target with `Self -> "" | `Id s -> " " ^ s in
      n ^ original_id
    in
    args |> List.map arg_to_string |> String.concat " ; "
end

module _ : S = Change_page

module Draw = struct
  let on = "draw"
  let action_name = on

  type args = ids_or_self

  let parse_args = Parse.parse_only_els
end

module _ : S = Draw

module Clear_draw = struct
  let on = "clear"
  let action_name = on

  type args = ids_or_self

  let parse_args = Parse.parse_only_els
end

module _ : S = Clear_draw

module Execute = struct
  type args = ids_or_self

  let on = "exec-at-unpause"
  let action_name = "exec"
  let parse_args = Parse.parse_only_els
end

module _ : S = Execute
