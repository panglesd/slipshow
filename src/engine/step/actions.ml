open Undoable.Syntax

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
    take_inside_quoted_string [] (idx + 1)
  in
  let parse_arg idx =
    match s.[idx] with
    | '"' -> quoted_string idx
    | _ ->
        let idx0 = idx in
        let idx = consume_non_ws idx in
        let arg = String.sub s idx0 (idx - idx0) in
        (arg, idx)
  in
  let repeat parser idx =
    let rec do_ acc idx =
      match parser idx with
      | None -> (List.rev acc, idx)
      | Some (x, idx) -> do_ (x :: acc) idx
    in
    do_ [] idx
  in
  let parse_nameds =
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
      | _ -> None
    in
    repeat parse_named
  in
  let parse_other idx =
    if idx >= String.length s then None
    else
      let idx = consume_ws idx in
      let res =
        match s.[idx] with '"' -> quoted_string idx | _ -> parse_arg idx
      in
      Some res
  in
  let parse_others = repeat parse_other in
  let nameds, idx = parse_nameds 0 in
  let idx = consume_ws idx in
  let others, _idx = parse_others idx in
  (nameds, others)

let parse_string s =
  try Ok (parse_string s)
  with _ (* TODO: finer grain catch and better error messages *) ->
    Error (`Msg "Failed when trying to parse argument")

(* Let's remove angstrom parsing, but keep it around if the manual parsing
   becomes too cumbersome.

   Angstrom adds 10th of Ko (out of eg 300Ko for simple presentations).

   So it's close to being negligible but not completely *)

(* let parse_string s = *)
(*   let open Angstrom in *)
(*   let quoted_string = *)
(*     let quoted_string_char = *)
(*       char '\\' *> choice [ char '"' *> return '"'; char '\\' *> return '\\' ] *)
(*     in *)
(*     char '"' *)
(*     *> many (quoted_string_char <|> satisfy (fun c -> c <> '"' && c <> '\\')) *)
(*     <* char '"' *)
(*     >>| fun chars -> String.of_seq (List.to_seq chars) *)
(*   in *)
(*   let is_ws = function *)
(*     | '\x20' | '\x0a' | '\x0d' | '\x09' -> true *)
(*     | _ -> false *)
(*   in *)
(*   let ws = skip_while is_ws in *)
(*   let named = *)
(*     let is_alpha c = *)
(*       ('a' <= c && c <= 'z') *)
(*       || ('A' <= c && c <= 'Z') *)
(*       || ('0' <= c && c <= '9') *)
(*       || c = '_' *)
(*     in *)
(*     let name = take_while is_alpha in *)
(*     let argument = quoted_string <|> take_till is_ws in *)
(*     ws *> char '~' *> name >>= fun name -> *)
(*     char ':' *> ws *> argument >>| fun arg -> (name, arg) *)
(*   in *)
(*   let rest = quoted_string <|> take_while (fun _ -> true) <* end_of_input in *)
(*   let parser = *)
(*     many named >>= fun named -> *)
(*     ws *> rest >>| fun main -> (named, main) *)
(*   in *)
(*   parse_string ~consume:All parser s |> Result.get_ok *)

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

let setup_pause elem =
  let open Undoable in
  let> () = Browser.set_class "pauseTarget" true elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      let> () = Browser.set_class "pauseAncestor" true elem in
      Browser.set_at "pauseAncestorMultiplicity" (Some (Jstr.of_int 1)) elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Browser.set_class "pauseAncestor" true elem
      | Some i ->
          let> () =
            Browser.set_at "pauseAncestorMultiplicity"
              (Some (Jstr.of_int (i + 1)))
              elem
          in
          Browser.set_class "pauseAncestor" true elem)

(* TODO: factor pause and setup_pause duplicated logic *)
let pause elem =
  let open Undoable in
  let> () = Browser.set_class "pauseTarget" false elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      Brr.Console.(
        log [ "Error: pauseAncestorMultiplicity was supposed to be some"; elem ]);
      Browser.set_class "pauseAncestor" false elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Browser.set_class "pauseAncestor" false elem
      | Some i when i <= 1 ->
          let> () = Browser.set_at "pauseAncestorMultiplicity" None elem in
          Browser.set_class "pauseAncestor" false elem
      | Some i ->
          Browser.set_at "pauseAncestorMultiplicity"
            (Some (Jstr.of_int (i - 1)))
            elem)

let up window elem = Universe.Move.up window elem
let down window elem = Universe.Move.down window elem
let center window elem = Universe.Move.center window elem

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

  let parse_elems elem v =
    let v = List.map Jstr.of_string v in
    match v with
    | [] -> [ elem ]
    | _ ->
        v
        |> List.filter_map (fun id ->
               Brr.El.find_first_by_selector (Jstr.concat [ Jstr.v "#"; id ]))

  let find_named_arg name named_args =
    List.find_map
      (function n, v when String.equal n name -> Some v | _ -> None)
      named_args

  let parse_args elem s =
    let ( let$ ) = Fun.flip Result.map in
    let$ named_args, args = parse_string s in
    let elems = parse_elems elem args in
    let delay =
      find_named_arg "delay" named_args |> Option.map Float.of_string
    in
    let margin =
      find_named_arg "margin" named_args |> Option.map Float.of_string
    in
    { margin; delay; elems }

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

let scroll window elem = Universe.Move.scroll window elem
