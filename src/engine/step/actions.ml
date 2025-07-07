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
  let rec consume_ws idx = if is_ws idx then consume_ws (idx + 1) else idx in
  let rec consume_non_ws idx =
    if not (is_ws idx) then consume_non_ws (idx + 1) else idx
  in
  let rec consume_alpha idx =
    if is_alpha idx then consume_alpha (idx + 1) else idx
  in
  let rec parse_nameds acc idx =
    let parse_name idx =
      let idx0 = idx in
      let idx = consume_alpha idx in
      Format.printf "After consuming alpha idx is %d" idx;
      let name = String.sub s idx0 (idx - idx0) in
      (name, idx)
    in
    let parse_column idx =
      match s.[idx] with
      | ':' -> idx + 1
      | _ -> failwith "no : after named argument"
    in
    let parse_arg idx =
      let idx0 = idx in
      let idx = consume_non_ws idx in
      let arg = String.sub s idx0 (idx - idx0) in
      (arg, idx)
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
    match parse_named idx with
    | None -> (List.rev acc, idx)
    | Some (x, idx) -> parse_nameds (x :: acc) idx
  in
  let parse_others idx = String.sub s idx (String.length s - idx) in
  let nameds, idx = parse_nameds [] 0 in
  let idx = consume_ws idx in
  let others = parse_others idx in
  (nameds, others)

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
  let> () = Undoable.Browser.set_class "pauseTarget" true elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      let> () = Undoable.Browser.set_class "pauseAncestor" true elem in
      Undoable.Browser.set_at "pauseAncestorMultiplicity"
        (Some (Jstr.of_int 1))
        elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Undoable.Browser.set_class "pauseAncestor" true elem
      | Some i ->
          let> () =
            Undoable.Browser.set_at "pauseAncestorMultiplicity"
              (Some (Jstr.of_int (i + 1)))
              elem
          in
          Undoable.Browser.set_class "pauseAncestor" true elem)

let pause elem =
  let> () = Undoable.Browser.set_class "pauseTarget" false elem in
  do_to_root elem @@ fun elem ->
  match Brr.El.at (Jstr.v "pauseAncestorMultiplicity") elem with
  | None ->
      Brr.Console.(
        log [ "Error: pauseAncestorMultiplicity was supposed to be some"; elem ]);
      Undoable.Browser.set_class "pauseAncestor" false elem
  | Some i -> (
      match Jstr.to_int i with
      | None ->
          Brr.Console.(
            log [ "Error: wrong value to pauseAncestorMultiplicity:"; i ]);
          Undoable.Browser.set_class "pauseAncestor" false elem
      | Some i when i <= 1 ->
          let> () =
            Undoable.Browser.set_at "pauseAncestorMultiplicity" None elem
          in
          Undoable.Browser.set_class "pauseAncestor" false elem
      | Some i ->
          Undoable.Browser.set_at "pauseAncestorMultiplicity"
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

let focus window elems =
  let> () = State.Focus.push (Universe.State.get_coord ()) in
  (* We focus 1px more in order to avoid off-by-one error due to round errors *)
  Universe.Move.focus ~margin:(-1.) window elems

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
