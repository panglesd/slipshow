module W = Warnings

type 'a node = 'a W.node

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
  let quoted_string idx0 =
    let rec take_inside_quoted_string acc idx =
      if idx >= String.length s then failwith "Missing end of quote"
      else
        match s.[idx] with
        | '"' ->
            ( (acc |> List.rev |> List.to_seq |> String.of_seq, (idx0, idx - 1)),
              idx + 1 )
        | '\\' ->
            if idx + 1 >= String.length s then
              failwith "Unterminated escape sequence in quoted string"
            else take_inside_quoted_string (s.[idx + 1] :: acc) (idx + 2)
        | _ -> take_inside_quoted_string (s.[idx] :: acc) (idx + 1)
    in
    take_inside_quoted_string [] idx0
  in
  let parse_unquoted_string idx =
    let idx0 = idx in
    let idx = consume_non_ws idx in
    let arg = String.sub s idx0 (idx - idx0) in
    ((arg, (idx0, idx)), idx)
  in
  let parse_arg idx =
    match s.[idx] with
    | '"' -> quoted_string (idx + 1)
    | _ -> parse_unquoted_string idx
    | exception _ -> failwith ": needs something after"
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
    | exception _ -> failwith "no : after named argument"
  in
  let parse_named idx =
    let idx0 = consume_ws idx in
    match s.[idx0] with
    | '~' ->
        let idx = idx0 + 1 in
        let name, idx = parse_name idx in
        let () =
          if String.equal name "" then
            failwith "'~' needs to be followed by a name"
        in
        let name_loc = (idx0, idx) in
        let idx = parse_column idx in
        let arg, idx = parse_arg idx in
        Some (((name, name_loc), arg), idx)
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
    | _ -> Some (parse_arg idx, idx)
    | exception Invalid_argument _ -> None
  in
  let parse_one idx =
    let ( let$ ) x f = match x with Some _ as x -> x | None -> f () in
    let ( let> ) x f = Option.map f x in
    let$ () =
      let> named, idx = parse_named idx in
      (`Named named, idx)
    in
    let$ () =
      let> (), idx' = parse_semicolon idx in
      (`Semicolon idx', idx')
    in
    let> (p, idx'), _idx = parse_positional idx in
    (`Positional p, idx')
  in
  let parse_all = repeat parse_one in
  let parsed, _ = parse_all 0 in
  let (unfinished_acc, loc), parsed =
    List.fold_left
      (fun ((current_acc, idx0), global_acc) -> function
        | `Semicolon idx ->
            (([], idx), (List.rev current_acc, (idx0, idx)) :: global_acc)
        | (`Positional _ | `Named _) as x ->
            ((x :: current_acc, idx0), global_acc))
      (([], 0), [])
      parsed
  in
  let parsed =
    (List.rev unfinished_acc, (loc, String.length s)) :: parsed |> List.rev
  in
  parsed
  |> List.map @@ fun (l, loc) ->
     ( List.partition_map
         (function `Named x -> Left x | `Positional p -> Right p)
         l,
       loc )

let ( let+ ) x y = Result.map y x

module Smap = Map.Make (String)

type action = {
  name : string;
  named : (string node * W.loc) Smap.t;
  positional : string node list;
}

let parse_string ~action_name s : (_ W.t, _) result =
  let+ s =
    try Ok (parse_string s) with
    | Failure s -> Error (`Msg s)
    | _ (* TODO: finer grain catch and better error messages *) ->
        Error (`Msg "Failed when trying to parse argument")
  in
  let res, warnings =
    s
    |> List.map (fun ((named, positional), loc) ->
           let named, warnings =
             named
             |> List.fold_left
                  (fun (map, warnings) ((k, k_loc), (v, loc')) ->
                    match Smap.find_opt k map with
                    | None -> (Smap.add k ((v, loc'), k_loc) map, warnings)
                    | Some _ ->
                        (* let loc = _ in *)
                        let msg =
                          "Named argument '" ^ k
                          ^ "' is duplicated. This instance is ignored."
                        in
                        let w = W.Parsing_failure { msg; loc = k_loc } in
                        (map, w :: warnings))
                  (Smap.empty, [])
           in
           (({ name = action_name; named; positional }, loc), warnings))
    |> List.split
  in
  let warnings = List.concat warnings in
  (res, warnings)

let id x = x

type 'a description_named_atom =
  string * (string node -> ('a, [ `Msg of string ]) result)

type _ descr_tuple =
  | [] : unit descr_tuple
  | ( :: ) : 'a description_named_atom * 'b descr_tuple -> ('a * 'b) descr_tuple

type _ output_tuple =
  | [] : unit output_tuple
  | ( :: ) : 'a option * 'b output_tuple -> ('a * 'b) output_tuple

type 'a non_empty_list = 'a * 'a list

type ('named, 'positional) parsed = {
  p_named : 'named output_tuple;
  p_pos : 'positional node list;
}

let parsed_name (description_name, description_convert) action =
  Smap.find_opt description_name action.named
  |> Option.map (fun (((_, loc) as x), _) -> (description_convert x, loc))

let rec all_keys : type a. a descr_tuple -> string list =
 fun names ->
  match names with
  | [] -> []
  | (action_key, _) :: rest -> action_key :: all_keys rest

let check_is_unused : type a. action -> a descr_tuple -> unit =
 fun action descriptions ->
  let all_keys = all_keys descriptions in
  Smap.iter
    (fun key (_, loc) ->
      if List.mem key all_keys then ()
      else
        let possible_arguments = all_keys in
        W.add
          (UnusedArgument
             {
               action_name = action.name;
               argument_name = key;
               loc;
               possible_arguments;
             }))
    action.named

let rec parsed_names : type a. action -> a descr_tuple -> a output_tuple =
 fun action descriptions ->
  match descriptions with
  | [] -> []
  | description :: rest ->
      let parsed =
        match parsed_name description action with
        | None -> None
        | Some (Error (`Msg msg), loc) ->
            W.add @@ Parsing_failure { msg; loc };
            None
        | Some (Ok a, _) -> Some a
      in
      parsed :: parsed_names action rest

let parse_atom ~named ~positional (action, loc) =
  let p_named = parsed_names action named in
  check_is_unused action named;
  let p_pos =
    List.map (fun (x, loc) -> (positional x, loc)) action.positional
  in
  ({ p_named; p_pos }, loc)

open W.M

let parse ~action_name ~named ~positional s :
    (('named, 'pos) parsed node non_empty_list * W.warnor list, _) result =
  let+ parsed_string = parse_string ~action_name s in
  let$ parsed_string = parsed_string in
  W.with_ @@ fun () ->
  List.map (parse_atom ~named ~positional) parsed_string |> function
  | [] ->
      assert false
      (* An empty string would be parsed as [ [[None; None; ...], []] ] *)
  | a :: rest -> ((a, rest) : _ non_empty_list)

let merge_positional (h, t) =
  List.concat_map
    (fun ({ p_named = ([] : _ output_tuple); p_pos = p }, _loc) -> p)
    (h :: t)

let require_single_action ~action_name x =
  match x with
  | ((_, loc) as a), rest ->
      let warnings =
        match (rest : _ list) with
        | [] -> ([] : _ list)
        | rest ->
            let msg =
              "Action " ^ action_name
              ^ " does not support ';'-separated arguments"
            in
            let loc = W.range loc rest in
            [ W.Parsing_failure { msg; loc } ]
      in
      (a, warnings)

let require_single_positional ~action_name (x : _ list) =
  W.with_ @@ fun () ->
  match x with
  | [] -> None
  | a :: rest ->
      let () =
        match rest with
        | [] -> ()
        | (_, loc) :: rest ->
            let msg =
              "Action " ^ action_name ^ " does not support multiple arguments"
            and loc = W.range loc rest in
            W.add (Parsing_failure { msg; loc })
      in
      Some a

let no_args ~action_name s =
  let open W.M in
  let+ x = parse ~action_name ~named:[] ~positional:id s in
  let$ x = x in
  match x with
  | ({ p_named = []; p_pos = [] }, _loc), [] -> ((), [])
  | (_, loc), _ ->
      let msg = "The " ^ action_name ^ " action does not accept any argument" in
      ((), [ W.Parsing_failure { msg; loc } ])

let parse_only_els ~action_name s =
  let+ x, warnings = parse ~action_name ~named:[] ~positional:id s in
  let res = match merge_positional x with [] -> `Self | x -> `Ids x in
  (res, warnings)

let parse_only_el ~action_name s =
  let+ x, warnings = parse ~action_name ~named:[] ~positional:id s in
  match merge_positional x with
  | [] -> (`Self, warnings)
  | x :: rest ->
      let warnings =
        match rest with
        | [] -> warnings
        | (_, loc) :: _ ->
            let msg = "Expected a single ID" in
            let w = W.Parsing_failure { msg; loc } in
            w :: warnings
      in
      (`Id x, warnings)

let option_to_error error = function
  | Some x -> Ok x
  | None -> Error (`Msg error)

let duration =
  ( "duration",
    fun (x, _) ->
      x |> Float.of_string_opt |> option_to_error "Error during float parsing"
  )

let margin =
  ( "margin",
    fun (x, _) ->
      x |> Float.of_string_opt |> option_to_error "Error during float parsing"
  )
