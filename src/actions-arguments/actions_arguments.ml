module W = Warnings

type id_or_self = [ `Self | `Id of string W.node ]
type ids_or_self = [ `Self | `Ids of string W.node list ]

module type S = sig
  type args

  val on : string
  val action_name : string
  val parse_args : string -> (args W.t, [> `Msg of string ]) result
  val doc : string
end

module Pause = struct
  let on = "pause"
  let action_name = "pause"

  type args = [ `Self | `Ids of string W.node list ]

  let parse_args = Parse.parse_only_els ~action_name
  let doc = "Hide what follows, until the action is executed"
end

module _ : S = Pause

module type Move = sig
  type args = {
    margin : float option;
    duration : float option;
    target : id_or_self;
  }

  include S with type args := args
end

module Move (X : sig
  val on : string
  val action_name : string
  val doc : string
end) : Move = struct
  let on = X.on
  let action_name = X.action_name
  let doc = X.doc

  type args = {
    margin : float option;
    duration : float option;
    target : id_or_self;
  }

  let parse_args s =
    let ( let+ ) x f = Result.map f x in
    let open W.M in
    let+ x =
      Parse.parse ~action_name
        ~named:[ Parse.duration; Parse.margin ]
        ~positional:Parse.id s
    in
    let$ x = x in
    let$ res = Parse.require_single_action ~action_name:X.action_name x in
    match res with
    | { p_named = [ duration; margin ]; p_pos = positional }, _ -> (
        let$+ res =
          Parse.require_single_positional ~action_name:X.action_name positional
        in
        match res with
        | None -> { target = `Self; duration; margin }
        | Some positional -> { target = `Id positional; duration; margin })
end

module Up = Move (struct
  let on = "up-at-unpause"
  let action_name = "up"

  let doc =
    "Move the screen vertically so that the target is at the top of the screen"
end)

module _ : S = Up

module Down = Move (struct
  let on = "down-at-unpause"
  let action_name = "down"

  let doc =
    "Move the screen vertically so that the target is at the bottom of the \
     screen"
end)

module _ : S = Down

module Center = Move (struct
  let on = "center-at-unpause"
  let action_name = "center"

  let doc =
    "Move the screen vertically so that the target is at the center of the \
     screen"
end)

module _ : S = Center

module Scroll = Move (struct
  let on = "scroll-at-unpause"
  let action_name = "scroll"
  let doc = "Move the screen vertically until the element is fully visible"
end)

module _ : S = Scroll

module Enter = Move (struct
  let on = "enter-at-unpause"
  let action_name = "enter"
  let doc = "Enter a slide or a slip"
end)

module _ : S = Enter

module type SetClass = S with type args = ids_or_self

module SetClass (X : sig
  val on : string
  val action_name : string
  val doc : string
end) : SetClass = struct
  let on = X.on
  let action_name = X.action_name
  let doc = X.doc

  type args = ids_or_self

  let parse_args = Parse.parse_only_els ~action_name
end

module Unstatic = SetClass (struct
  let on = "unstatic-at-unpause"
  let action_name = "unstatic"
  let doc = "Remove the target from the document"
end)

module _ : S = Unstatic

module Static = SetClass (struct
  let on = "static-at-unpause"
  let action_name = "static"

  let doc =
    "Add the target to the document (if it was removed by the `unstatic` \
     action or the `.unstatic` class)"
end)

module _ : S = Static

module Reveal = SetClass (struct
  let on = "reveal-at-unpause"
  let action_name = "reveal"

  let doc =
    "Reveal the target (if it was hidden by the `unreveal` action or the \
     `.unrevealed` class)"
end)

module _ : S = Reveal

module Unreveal = SetClass (struct
  let on = "unreveal-at-unpause"
  let action_name = "unreveal"
  let doc = "Hide the target"
end)

module _ : S = Unreveal

module Emph = SetClass (struct
  let on = "emph-at-unpause"
  let action_name = "emph"
  let doc = "Emphasize the target"
end)

module _ : S = Emph

module Unemph = SetClass (struct
  let on = "unemph-at-unpause"
  let action_name = "unemph"

  let doc =
    "Remove the emphasize from the target (if it was emphasize through the \
     `emph` action or the `.emphasized` class)"
end)

module _ : S = Unemph

module Step = struct
  type args = unit

  let on = "step"
  let action_name = on
  let parse_args s = Parse.no_args ~action_name s
  let doc = "Does nothing. Useful to change slips."
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
    let ( let+ ) = Fun.flip Result.map in
    let+ x =
      Parse.parse ~action_name
        ~named:[ Parse.duration; Parse.margin ]
        ~positional:Parse.id s
    in
    let open W.M in
    let$ x = x in
    let$+ res = Parse.require_single_action ~action_name x in
    match res with
    | { p_named = [ duration; margin ]; p_pos = [] }, _loc ->
        { target = `Self; duration; margin }
    | { p_named = [ duration; margin ]; p_pos = positional }, _loc ->
        let target = `Ids positional in
        { target; duration; margin }

  let doc =
    "Move and rescale the screen to make see all the targets the biggest \
     possible"
end

module _ : S = Focus

module Unfocus = struct
  type args = unit

  let on = "unfocus-at-unpause"
  let action_name = "unfocus"
  let parse_args s = Parse.no_args ~action_name s
  let doc = "Move back to where the screen was before starting focusing"
end

module _ : S = Unfocus

module Speaker_note = struct
  let on = "speaker-note"
  let action_name = on

  type args = id_or_self

  let parse_args = Parse.parse_only_el ~action_name
  let doc = "Send the content of the target to the speaker notes"
end

module _ : S = Speaker_note

module Play_media = struct
  let on = "play-media"
  let action_name = "play-media"

  type args = ids_or_self

  let parse_args = Parse.parse_only_els ~action_name
  let doc = "Play the target media (audio or video)"
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

  let parse_change (s, loc) =
    if String.equal "all" s then Some All
    else
      match int_of_string_opt s with
      | None -> (
          match String.split_on_char '-' s with
          | [ a; b ] -> (
              match (int_of_string_opt a, int_of_string_opt b) with
              | Some a, Some b -> Some (Range (a, b))
              | _ ->
                  let msg = "Could not parse parameter" in
                  W.add (W.Parsing_failure { msg; loc });
                  None)
          | _ ->
              let msg = "Could not parse parameter" in
              W.add (W.Parsing_failure { msg; loc });
              None)
      | Some x -> (
          match s.[0] with
          | '+' | '-' -> Some (Relative x)
          | _ -> Some (Absolute x))

  let parse_single_action
      { Parse.p_named = ([ n_opt ] : _ Parse.output_tuple); p_pos = elem_ids } =
    let n = Option.value ~default:[ Relative 1 ] n_opt in
    let open W.M in
    let$+ id_or_self =
      match elem_ids with
      | [] -> (`Self, [])
      | [ id ] -> (`Id id, [])
      | ((_, loc) as id) :: rest ->
          let loc = W.range loc rest in
          let msg = "Expected single id. Considering only the first one." in
          let w = W.Parsing_failure { msg; loc } in
          (`Id id, [ w ])
    in
    { n; target = id_or_self }

  let parse_n (s, (loc_min, _)) =
    let l =
      String.split_on_char ' ' s
      |> List.fold_left
           (fun (acc, idx) x ->
             let l = String.length x in
             if l = 0 then (acc, idx + 1)
             else ((x, (idx, idx + l)) :: acc, idx + l + 1))
           ([], loc_min)
      |> fun (x, _) -> List.rev x
    in
    l |> List.filter_map parse_change |> Result.ok

  let parse_args s =
    let open W.M in
    let+ res =
      Parse.parse ~action_name ~named:[ ("n", parse_n) ] ~positional:Fun.id s
    in
    let$ ac, actions = res in
    let actions = ac :: actions in
    let warnings, res =
      List.fold_left_map
        (fun acc (action, _loc) ->
          let res, w = parse_single_action action in
          (w :: acc, res))
        [] actions
    in
    (res, List.concat warnings)

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
      let original_id =
        match target with `Self -> "" | `Id (s, _) -> " " ^ s
      in
      n ^ original_id
    in
    args |> List.map arg_to_string |> String.concat " ; "

  let doc = "Change the currently visible page of a carousel or pdf"
end

module _ : S = Change_page

module Draw = struct
  let on = "draw"
  let action_name = on

  type args = ids_or_self

  let parse_args = Parse.parse_only_els ~action_name
  let doc = "Draw a pre-recorded target drawing"
end

module _ : S = Draw

module Clear_draw = struct
  let on = "clear"
  let action_name = on

  type args = ids_or_self

  let parse_args = Parse.parse_only_els ~action_name
  let doc = "Clear a pre-recorded target drawing"
end

module _ : S = Clear_draw

module Execute = struct
  type args = ids_or_self

  let on = "exec-at-unpause"
  let action_name = "exec"
  let parse_args = Parse.parse_only_els ~action_name
  let doc = "Execute the target slip script"
end

module _ : S = Execute

let all_actions =
  [
    (module Enter : S);
    (module Clear_draw : S);
    (module Draw : S);
    (module Pause : S);
    (module Step : S);
    (module Up : S);
    (module Down : S);
    (module Center : S);
    (module Scroll : S);
    (module Change_page : S);
    (module Focus : S);
    (module Unfocus : S);
    (module Execute : S);
    (module Unstatic : S);
    (module Static : S);
    (module Reveal : S);
    (module Unreveal : S);
    (module Emph : S);
    (module Unemph : S);
    (module Speaker_note : S);
    (module Play_media : S);
  ]
