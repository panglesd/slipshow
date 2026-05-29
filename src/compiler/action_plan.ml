open Actions_arguments
open Ast.Action_plan

let targets arg =
  let id_or_self = function `Self -> [] | `Id id -> [ id ] in
  let ids_or_self = function `Self -> [] | `Ids ids -> ids in
  match arg with
  | Enter { target; _ }
  | Speaker_note target
  | Up { target; _ }
  | Down { target; _ }
  | Center { target; _ }
  | Scroll { target; _ } ->
      id_or_self target
  | Focus { target = targets; _ }
  | Execute targets
  | Pause targets
  | Draw targets
  | Unstatic targets
  | Static targets
  | Reveal targets
  | Unreveal targets
  | Emph targets
  | Play_media targets
  | Unemph targets
  | Clear_draw targets ->
      ids_or_self targets
  | Unfocus _ | Step _ | Auto_next _ -> []
  | Change_page argl ->
      List.concat_map
        (function
          | { Actions_arguments.Change_page.target; _ } -> id_or_self target)
        argl

let kv_attribute_to_step id_map bol
    (((key, _), value) as kv : Cmarkit.Attributes.kv) =
  let ( let* ) = Option.bind in
  let* (module X) =
    List.find_opt (fun (module X : S) -> String.equal key X.on) all_actions
  in
  let value, val_loc =
    match value with
    | None -> ("", Cmarkit.Textloc.none)
    | Some (value, meta) -> (value.v, Cmarkit.Meta.textloc meta)
  in
  let ( let< ) x f =
    match x with
    | Error (`Msg msg) ->
        Diagnosis.add
          (ParsingError { action = X.action_name; msg; loc = val_loc });
        None
    | Ok (x, warnings) ->
        List.iter
          (fun warnor ->
            Diagnosis.add @@ ParsingWarnor { warnor; loc = val_loc })
          warnings;
        Some (f x)
  in
  match X.repr with
  | Auto_next ->
      let< args = Auto_next.parse_args value in
      let id_map = Checks.auto_next id_map ~args ~val_loc bol in
      (Auto_next args, kv, id_map)
  | Enter ->
      let< args = Enter.parse_args value in
      let id_map = Checks.enter id_map ~args ~val_loc bol in
      (Enter args, kv, id_map)
  | Clear_draw ->
      let< args = Clear_draw.parse_args value in
      let id_map = Checks.clear id_map ~args ~val_loc bol in
      (Clear_draw args, kv, id_map)
  | Draw ->
      let< args = Draw.parse_args value in
      let id_map = Checks.draw id_map ~args ~val_loc bol in
      (Draw args, kv, id_map)
  | Pause ->
      let< args = Pause.parse_args value in
      let id_map = Checks.pause id_map ~args ~val_loc bol in
      (Pause args, kv, id_map)
  | Step ->
      let< args = Step.parse_args value in
      let id_map = Checks.step id_map ~args ~val_loc bol in
      (Step args, kv, id_map)
  | Up ->
      let< args = Up.parse_args value in
      let id_map = Checks.up id_map ~args ~val_loc bol in
      (Up args, kv, id_map)
  | Down ->
      let< args = Down.parse_args value in
      let id_map = Checks.down id_map ~args ~val_loc bol in
      (Down args, kv, id_map)
  | Center ->
      let< args = Center.parse_args value in
      let id_map = Checks.center id_map ~args ~val_loc bol in
      (Center args, kv, id_map)
  | Scroll ->
      let< args = Scroll.parse_args value in
      let id_map = Checks.scroll id_map ~args ~val_loc bol in
      (Scroll args, kv, id_map)
  | Change_page ->
      let< args = Change_page.parse_args value in
      let id_map = Checks.change_page id_map ~args ~val_loc bol in
      (Change_page args, kv, id_map)
  | Focus ->
      let< args = Focus.parse_args value in
      let id_map = Checks.focus id_map ~args ~val_loc bol in
      (Focus args, kv, id_map)
  | Unfocus ->
      let< args = Unfocus.parse_args value in
      let id_map = Checks.unfocus id_map ~args ~val_loc bol in
      (Unfocus args, kv, id_map)
  | Execute ->
      let< args = Execute.parse_args value in
      let id_map = Checks.exec id_map ~args ~val_loc bol in
      (Execute args, kv, id_map)
  | Unstatic ->
      let< args = Unstatic.parse_args value in
      let id_map = Checks.unstatic id_map ~args ~val_loc bol in
      (Unstatic args, kv, id_map)
  | Static ->
      let< args = Static.parse_args value in
      let id_map = Checks.static id_map ~args ~val_loc bol in
      (Static args, kv, id_map)
  | Reveal ->
      let< args = Reveal.parse_args value in
      let id_map = Checks.reveal id_map ~args ~val_loc bol in
      (Reveal args, kv, id_map)
  | Unreveal ->
      let< args = Unreveal.parse_args value in
      let id_map = Checks.unreveal id_map ~args ~val_loc bol in
      (Unreveal args, kv, id_map)
  | Emph ->
      let< args = Emph.parse_args value in
      let id_map = Checks.emph id_map ~args ~val_loc bol in
      (Emph args, kv, id_map)
  | Unemph ->
      let< args = Unemph.parse_args value in
      let id_map = Checks.unemph id_map ~args ~val_loc bol in
      (Unemph args, kv, id_map)
  | Speaker_note ->
      let< args = Speaker_note.parse_args value in
      let id_map = Checks.speaker_note id_map ~args ~val_loc bol in
      (Speaker_note args, kv, id_map)
  | Play_media ->
      let< args = Play_media.parse_args value in
      let id_map = Checks.play_media id_map ~args ~val_loc bol in
      (Play_media args, kv, id_map)

let attributes_to_step id_map attrs elem =
  let kv = Cmarkit.Attributes.kv_attributes (fst attrs) in
  let id_map, actions =
    List.fold_left
      (fun (id_map, actions) kv ->
        match kv_attribute_to_step id_map elem kv with
        | None -> (id_map, actions)
        | Some (arg, kv, id_map) -> (id_map, (arg, kv) :: actions))
      (id_map, []) kv
  in
  let actions = List.rev actions in
  match actions with
  | [] -> None
  | actions -> Some ({ actions; elem; attrs }, id_map)

open Cmarkit

let folder =
  let block f ((steps, id_map) as acc) c =
    let acc =
      match Ast.Utils.Block.get_attribute c with
      | None -> acc
      | Some (_, attrs) -> (
          let () = Checks.Unknown_attributes.no_unknown_attributes attrs in
          match attributes_to_step id_map attrs (`Block c) with
          | None -> acc
          | Some (step, id_map) -> (step :: steps, id_map))
    in
    Folder.ret @@ Ast.Folder.continue_block f c acc
  in
  let inline f ((steps, id_map) as acc) i =
    let acc =
      match Ast.Utils.Inline.get_attribute i with
      | None -> acc
      | Some (_, attrs) -> (
          let () = Checks.Unknown_attributes.no_unknown_attributes attrs in
          match attributes_to_step id_map attrs (`Inline i) with
          | None -> acc
          | Some (step, id_map) -> (step :: steps, id_map))
    in
    Folder.ret @@ Ast.Folder.continue_inline f i acc
  in
  Ast.Folder.fold_units' ~block ~inline

let rec merge_id_maps visited (unit : Ast.unit') (units : Ast.unit' Fpath.Map.t)
    id_map =
  if Fpath.Set.mem unit.path visited then
    (* TODO: Show as error that there is a cyclic dependency problem *)
    id_map
  else
    let visited = Fpath.Set.add unit.path visited in
    let id_map =
      Id_map.SMap.union
        (fun _id p1 p2 -> Some (Id_map.Unionable_set.union p1 p2))
        unit.Ast.id_map id_map
    in
    let deps = unit.deps in
    let id_map =
      Fpath.Map.fold
        (fun fpath _ id_map ->
          match Fpath.Map.find_opt fpath units with
          | None -> id_map
          | Some unit -> merge_id_maps visited unit units id_map)
        deps id_map
    in
    id_map

let merge_id_maps (unit : Ast.unit') (units : Ast.unit' Fpath.Map.t) id_map =
  let id_map =
    merge_id_maps Fpath.Set.empty
      (unit : Ast.unit')
      (units : Ast.unit' Fpath.Map.t)
      id_map
  in
  let () =
    Id_map.SMap.iter
      (fun id u ->
        let occurrences =
          u |> Id_map.Unionable_set.to_list
          |> List.map (fun { Id_map.id = _id, meta1; elem = _; meta = _ } ->
              Meta.textloc meta1)
        in
        match occurrences with
        | [] | _ :: [] -> ()
        | _ :: _ :: _ -> Diagnosis.add @@ DuplicateID { id; occurrences })
      id_map
  in
  id_map

let execute entry_point units =
  let id_map = merge_id_maps entry_point units Id_map.SMap.empty in
  let id_map =
    Id_map.SMap.map (fun definition -> { Id_map.definition; usage = [] }) id_map
  in
  folder ([], id_map) entry_point units |> fun (steps, id_map) ->
  (List.rev steps, id_map)
