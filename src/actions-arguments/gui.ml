type t = { x : int option; y : int option; scale : float option }

let result_of_option s = function Some x -> Ok x | None -> Error (`Msg s)

let int (i, _loc) =
  i |> int_of_string_opt |> result_of_option "Expected an integer"

let float (i, _loc) =
  i |> float_of_string_opt |> result_of_option "Expected a float"

let parse s =
  let res =
    Parse.parse ~action_name:"gui"
      ~named:[ ("x", int); ("y", int); ("scale", float) ]
      ~positional:Fun.id s
  in
  match res with
  | Ok ((({ p_named = [ x; y; scale ]; p_pos = [] }, _loc), []), warnings) ->
      let x = Option.map fst x in
      let y = Option.map fst y in
      let scale = Option.map fst scale in
      Ok ({ x; y; scale }, warnings)
  | Error _ as e -> e
  | Ok ((_, _ :: _), _) ->
      Error
        (`Msg "Invalid syntax for gui. Use ~x:<int> ~y:<int> ~scale:<float>.")
  | Ok ((({ p_named = _; p_pos = _ :: _ }, _), []), _) ->
      Error
        (`Msg
           "Invalid syntax for gui. Use ~x:<int> ~y:<int> ~scale:<float>, \
            without ';'")

let to_string { x; y; scale } =
  let x = Option.map (fun x -> "~x:" ^ string_of_int x) x in
  let y = Option.map (fun y -> "~y:" ^ string_of_int y) y in
  let scale =
    Option.map (fun scale -> "~scale:" ^ Printf.sprintf "%f" scale) scale
  in
  [ x; y; scale ] |> List.filter_map Fun.id |> String.concat " "
