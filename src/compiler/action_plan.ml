open Actions_arguments

type arg =
  | Enter of Enter.args
  | Clear_draw of Clear_draw.args
  | Draw of Draw.args
  | Pause of Pause.args
  | Step of Step.args
  | Up of Up.args
  | Down of Down.args
  | Center of Center.args
  | Scroll of Scroll.args
  | Change_page of Change_page.args
  | Focus of Focus.args
  | Unfocus of Unfocus.args
  | Execute of Execute.args
  | Unstatic of Unstatic.args
  | Static of Static.args
  | Reveal of Reveal.args
  | Unreveal of Unreveal.args
  | Emph of Emph.args
  | Unemph of Unemph.args
  | Speaker_note of Speaker_note.args
  | Play_media of Play_media.args

type action = arg * Cmarkit.Attributes.kv

type step = {
  actions : action list;
  elem : Ast.Bol.t;
  attrs : Cmarkit.(Attributes.t node);
}
(** A step is the list of actions that are going to be executed at the same
    time. Ordered by presence in the file *)

type t = step list
(** A plan is a list of steps. Steps are ordered by order of execution, which
    corresponds to reading order. *)

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
  | Enter ->
      let< args = Enter.parse_args value in
      Checks.enter id_map ~args ~val_loc bol;
      (Enter args, kv)
  | Clear_draw ->
      let< args = Clear_draw.parse_args value in
      Checks.clear id_map ~args ~val_loc bol;
      (Clear_draw args, kv)
  | Draw ->
      let< args = Draw.parse_args value in
      Checks.draw id_map ~args ~val_loc bol;
      (Draw args, kv)
  | Pause ->
      let< args = Pause.parse_args value in
      Checks.pause id_map ~args ~val_loc bol;
      (Pause args, kv)
  | Step ->
      let< args = Step.parse_args value in
      Checks.step id_map ~args ~val_loc bol;
      (Step args, kv)
  | Up ->
      let< args = Up.parse_args value in
      Checks.up id_map ~args ~val_loc bol;
      (Up args, kv)
  | Down ->
      let< args = Down.parse_args value in
      Checks.down id_map ~args ~val_loc bol;
      (Down args, kv)
  | Center ->
      let< args = Center.parse_args value in
      Checks.center id_map ~args ~val_loc bol;
      (Center args, kv)
  | Scroll ->
      let< args = Scroll.parse_args value in
      Checks.scroll id_map ~args ~val_loc bol;
      (Scroll args, kv)
  | Change_page ->
      let< args = Change_page.parse_args value in
      Checks.change_page id_map ~args ~val_loc bol;
      (Change_page args, kv)
  | Focus ->
      let< args = Focus.parse_args value in
      Checks.focus id_map ~args ~val_loc bol;
      (Focus args, kv)
  | Unfocus ->
      let< args = Unfocus.parse_args value in
      Checks.unfocus id_map ~args ~val_loc bol;
      (Unfocus args, kv)
  | Execute ->
      let< args = Execute.parse_args value in
      Checks.exec id_map ~args ~val_loc bol;
      (Execute args, kv)
  | Unstatic ->
      let< args = Unstatic.parse_args value in
      Checks.unstatic id_map ~args ~val_loc bol;
      (Unstatic args, kv)
  | Static ->
      let< args = Static.parse_args value in
      Checks.static id_map ~args ~val_loc bol;
      (Static args, kv)
  | Reveal ->
      let< args = Reveal.parse_args value in
      Checks.reveal id_map ~args ~val_loc bol;
      (Reveal args, kv)
  | Unreveal ->
      let< args = Unreveal.parse_args value in
      Checks.unreveal id_map ~args ~val_loc bol;
      (Unreveal args, kv)
  | Emph ->
      let< args = Emph.parse_args value in
      Checks.emph id_map ~args ~val_loc bol;
      (Emph args, kv)
  | Unemph ->
      let< args = Unemph.parse_args value in
      Checks.unemph id_map ~args ~val_loc bol;
      (Unemph args, kv)
  | Speaker_note ->
      let< args = Speaker_note.parse_args value in
      Checks.speaker_note id_map ~args ~val_loc bol;
      (Speaker_note args, kv)
  | Play_media ->
      let< args = Play_media.parse_args value in
      Checks.play_media id_map ~args ~val_loc bol;
      (Play_media args, kv)

let attributes_to_step id_map attrs elem =
  let kv = Cmarkit.Attributes.kv_attributes (fst attrs) in
  let actions = List.filter_map (kv_attribute_to_step id_map elem) kv in
  match actions with [] -> None | actions -> Some { actions; elem; attrs }

open Cmarkit

let folder ~id_map =
  let block f acc c =
    let acc =
      match Ast.Utils.Block.get_attribute c with
      | None -> acc
      | Some (_, attrs) -> (
          let () = Checks.Unknow_attributes.no_unknown_attributes attrs in
          match attributes_to_step id_map attrs (`Block c) with
          | None -> acc
          | Some x -> x :: acc)
    in
    Folder.ret @@ Ast.Folder.continue_block f c acc
  in
  let inline f acc i =
    let acc =
      match Ast.Utils.Inline.get_attribute i with
      | None -> acc
      | Some (_, attrs) -> (
          let () = Checks.Unknow_attributes.no_unknown_attributes attrs in
          match attributes_to_step id_map attrs (`Inline i) with
          | None -> acc
          | Some x -> x :: acc)
    in
    Folder.ret @@ Ast.Folder.continue_inline f i acc
  in
  Ast.Folder.make ~block ~inline ()

let execute ~id_map ast =
  Folder.fold_doc (folder ~id_map) [] ast.Ast.doc |> List.rev
