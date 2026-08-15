type t = {
  x : int option;
  y : int option;
  scale : float option;
  width : int option;
  height : int option;
}

let result_of_option s = function Some x -> Ok x | None -> Error (`Msg s)

let int (i, _loc) =
  i |> int_of_string_opt |> result_of_option "Expected an integer"

let float (i, _loc) =
  i |> float_of_string_opt |> result_of_option "Expected a float"

let correct_syntax = "~x:<int> ~y:<int> ~scale:<float> ~w:<int> ~h:<int>"

let parse s =
  let res =
    Parse.parse ~action_name:Common_types.Special_strings.gui
      ~named:
        [ ("x", int); ("y", int); ("scale", float); ("w", int); ("h", int) ]
      ~positional:Fun.id s
  in
  match res with
  | Ok
      ( (({ p_named = [ x; y; scale; width; height ]; p_pos = [] }, _loc), []),
        warnings ) ->
      let x = Option.map fst x in
      let y = Option.map fst y in
      let scale = Option.map fst scale in
      let width = Option.map fst width in
      let height = Option.map fst height in
      Ok ({ x; y; scale; width; height }, warnings)
  | Error _ as e -> e
  | Ok ((_, _ :: _), _) ->
      Error (`Msg ("Invalid syntax for gui. Use " ^ correct_syntax ^ "."))
  | Ok ((({ p_named = _; p_pos = _ :: _ }, _), []), _) ->
      Error
        (`Msg ("Invalid syntax for gui. Use " ^ correct_syntax ^ ", without ';'"))

let to_string { x; y; scale; width; height } =
  let x = Option.map (fun x -> "~x:" ^ string_of_int x) x in
  let y = Option.map (fun y -> "~y:" ^ string_of_int y) y in
  let scale =
    Option.map (fun scale -> "~scale:" ^ Printf.sprintf "%f" scale) scale
  in
  let width = Option.map (fun width -> "~w:" ^ string_of_int width) width in
  let height = Option.map (fun height -> "~h:" ^ string_of_int height) height in
  [ x; y; scale; width; height ] |> List.filter_map Fun.id |> String.concat " "
