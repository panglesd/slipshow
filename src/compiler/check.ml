open Cmarkit
module M = Map.Make (String)

module Is = struct
  let slip_script _bol = failwith "TODO"
  let speaker_note _bol = failwith "TODO"
end

let act_only_on_attributes_with_actions (module A : Actions_arguments.S) attrs f
    =
  let ex = Attributes.find A.on attrs in
  match ex with None -> () | Some (_, value) -> f value

let parse_args (type args)
    (module A : Actions_arguments.S with type args = args) attrs f =
  act_only_on_attributes_with_actions (module A) attrs @@ fun value ->
  let value, val_loc =
    match value with
    | None -> ("", Textloc.none)
    | Some ({ Attributes.v; _ }, meta) -> (v, Meta.textloc meta)
  in
  let args = A.parse_args value in
  match args with
  | Error (`Msg msg) ->
      Diagnosis.add
      @@ ParsingError { action = A.action_name; msg; loc = val_loc }
  | Ok (args, warnings) ->
      List.iter
        (fun warnor -> Diagnosis.add @@ ParsingWarnor { warnor; loc = val_loc })
        warnings;
      f args val_loc

let handle_id_get id_map val_loc (id, loc) =
  match M.find_opt id id_map with
  | None ->
      let loc = Diagnosis.loc_of_ploc val_loc loc in
      Diagnosis.add @@ MissingID { id; loc };
      None (* TODO: warning *)
  | Some (_, bol, _) -> Some bol

let handle_id id_map val_loc (id, loc) =
  handle_id_get id_map val_loc (id, loc) |> ignore

let handle_ids id_map val_loc ids = List.iter (handle_id id_map val_loc) ids

let exec id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Execute) attrs @@ fun args val_loc ->
  let targets =
    match args with
    | `Self -> [ block_or_inline ]
    | `Ids ids -> List.filter_map (handle_id_get id_map val_loc) ids
  in
  List.iter
    (function
      | `Block _ -> () (* TODO: do *)
      | `Inline i ->
          let loc_block = Inline.meta i |> Meta.textloc in
          let loc_reason = val_loc in
          Diagnosis.add @@ WrongType { loc_reason; loc_block })
    targets;
  ()

type bol = [ `Block of Block.t | `Inline of Inline.t ]
type id_map = ((string * Meta.t) * bol * Meta.t) M.t

let move (module A : Actions_arguments.Move) (id_map : id_map) attrs
    (_block_or_inline : bol) =
  parse_args (module A) attrs @@ fun args val_loc ->
  match args.target with `Self -> () | `Id id -> handle_id id_map val_loc id

let up = move (module Actions_arguments.Up)
let down = move (module Actions_arguments.Down)
let center = move (module Actions_arguments.Center)
let scroll = move (module Actions_arguments.Scroll)
let enter = move (module Actions_arguments.Enter)

let focus (id_map : id_map) attrs _block_or_inline =
  parse_args (module Actions_arguments.Focus) attrs @@ fun args val_loc ->
  match args.target with
  | `Self -> ()
  | `Ids ids -> handle_ids id_map val_loc ids

let unfocus (_id_map : id_map) attrs _block_or_inline =
  parse_args (module Actions_arguments.Unfocus) attrs @@ fun _ _ -> ()

let set_class (module A : Actions_arguments.SetClass) (id_map : id_map) attrs
    (_block_or_inline : bol) =
  parse_args (module A) attrs @@ fun args val_loc ->
  match args with `Self -> () | `Ids ids -> handle_ids id_map val_loc ids

let unstatic = set_class (module Actions_arguments.Unstatic)
let static = set_class (module Actions_arguments.Static)
let reveal = set_class (module Actions_arguments.Reveal)
let unreveal = set_class (module Actions_arguments.Unreveal)
let emph = set_class (module Actions_arguments.Emph)
let unemph = set_class (module Actions_arguments.Unemph)

let speaker_note id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Speaker_note) attrs
  @@ fun args val_loc ->
  let bol =
    match args with
    | `Self -> block_or_inline
    | `Id id -> handle_id_get id_map val_loc id
  in
  match bol with
  | Some b when Is.speaker_note b -> ()
  | _ ->
      (* TODO: must be a speaker note *)
      ()

let play_media _id_map _attrs _block_or_inline = failwith "TODO"
let change_page _id_map _attrs _block_or_inline = failwith "TODO"
let draw _id_map _attrs _block_or_inline = failwith "TODO"
let clear_draw _id_map _attrs _block_or_inline = failwith "TODO"
