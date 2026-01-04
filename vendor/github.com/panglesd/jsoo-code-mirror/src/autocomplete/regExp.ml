open Brr

type t = Jv.t

include (Jv.Id : Jv.CONV with type t := t)

let regexp = Jv.get (Window.to_jv G.window) "RegExp"

type opts = Indices | Global | Ignore | Multiline | DotAll | Unicode | Sticky

let opts_to_string = function
  | Indices -> "d"
  | Global -> "g"
  | Ignore -> "i"
  | Multiline -> "m"
  | DotAll -> "s"
  | Unicode -> "u"
  | Sticky -> "y"

let create ?(opts = []) s =
  let opts =
    match List.length opts with
    | 0 -> Jv.undefined
    | _ ->
        let options = List.sort_uniq Stdlib.compare opts in
        let opt_string =
          List.fold_left (fun acc t -> acc ^ opts_to_string t) "" options
        in
        Jv.of_string opt_string
  in
  Jv.new' regexp [| Jv.of_string s; opts |]

type result = Jv.t

let get_full_string_match res =
  let arr = Jv.to_jv_array res in
  arr.(0) |> Jv.to_string

let get_index res = Jv.Int.get res "index"

let get_indices res =
  let jv = Jv.get res "indices" in
  match Jv.is_null jv with
  | true -> []
  | false ->
      let conv arr =
        let indices = Jv.to_array Jv.to_int arr in
        (indices.(0), indices.(1))
      in
      Jv.to_list conv jv

let get_substring_matches res =
  let arr = Jv.to_jv_array res in
  let length = Array.length arr in
  Array.sub arr 1 length |> Array.to_list |> List.map Jv.to_string

let exec' t s = Jv.to_option Jv.Id.to_jv @@ Jv.call t "exec" [| Jv.of_jstr s |]
let exec t s = exec' t @@ Jstr.v s
