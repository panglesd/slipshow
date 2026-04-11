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

module Check = struct
  module Unknow_attributes = struct
    module SSet = Set.Make (String)

    let all_actions =
      List.map
        (fun (module A : Actions_arguments.S) -> A.on)
        Actions_arguments.all_actions
      |> SSet.of_list

    let all_special = Special_attrs.all_attrs |> SSet.of_list

    let all_attributes = [
      "accept";"accept-charset";"accesskey";"action";"align";"allow";"alpha";"alt";"as";"async";"autocapitalize";"autocomplete";"autoplay";"background";"bgcolor";"border";"capture";"charset";"checked";"cite";"class";"color";"colorspace";"cols";"colspan";"content";"contenteditable";"controls";"coords";"crossorigin";"csp";"data";"datetime";"decoding";"default";"defer";"dir";"dirname";"disabled";"download";"draggable";"enctype";"enterkeyhint";"elementtiming";"fetchpriority";"for";"form";"formaction";"formenctype";"formmethod";"formnovalidate";"formtarget";"headers";"height";"hidden";"high";"href";"hreflang";"http-equiv";"id";"integrity";"inputmode";"ismap";"itemprop";"kind";"label";"lang";"language";"loading";"list";"loop";"low";"max";"maxlength";"minlength";"media";"method";"min";"multiple";"muted";"name";"novalidate";"open";"optimum";"pattern";"ping";"placeholder";"playsinline";"poster";"preload";"readonly";"referrerpolicy";"rel";"required";"reversed";"role";"rows";"rowspan";"sandbox";"scope";"selected";"shape";"size";"sizes";"slot";"span";"spellcheck";"src";"srcdoc";"srclang";"srcset";"start";"step";"style";"summary";"tabindex";"target";"title";"translate";"type";"usemap";"value";"width";"wrap" ]
      |> SSet.of_list
    [@@ocamlformat "disable"]

    let check_attribute key loc =
      if SSet.mem key all_actions then ()
      else if SSet.mem key all_special then ()
      else if SSet.mem key all_attributes then ()
      else if String.starts_with ~prefix:"data-" key then ()
      else if String.starts_with ~prefix:"children:" key then ()
      else Diagnosis.add (UnknownAttribute { attr = key; loc })

    let no_unknown_attributes (attrs, _) =
      let kv = Cmarkit.Attributes.kv_attributes attrs in
      List.iter
        (fun ((key, meta), _value) ->
          check_attribute key (Cmarkit.Meta.textloc meta))
        kv
  end

  module Is = struct
    let not (f, e) = ((fun x -> not (f x)), "not " ^ e)
    let ( ||| ) (f1, e1) (f2, e2) = ((fun x -> f1 x || f2 x), e1 ^ " or " ^ e2)

    let slip (bol : Ast.Bol.t) =
      match bol with `Block (Ast.S_block (Slip _)) -> true | _ -> false

    let slip = (slip, "slip")

    let slide (bol : Ast.Bol.t) =
      match bol with `Block (Ast.S_block (Slide _)) -> true | _ -> false

    let slide = (slide, "slide")

    let carousel (bol : Ast.Bol.t) =
      match bol with `Block (Ast.S_block (Carousel _)) -> true | _ -> false

    let carousel = (carousel, "carousel")

    let pdf (bol : Ast.Bol.t) =
      match bol with `Inline (Ast.S_inline (Pdf _)) -> true | _ -> false

    let pdf = (pdf, "pdf")

    let video (bol : Ast.Bol.t) =
      match bol with `Inline (Ast.S_inline (Video _)) -> true | _ -> false

    let video = (video, "video")

    let audio (bol : Ast.Bol.t) =
      match bol with `Inline (Ast.S_inline (Audio _)) -> true | _ -> false

    let audio = (audio, "audio")
    let playable_media = video ||| audio

    let slip_script (bol : Ast.Bol.t) =
      match bol with `Block (Ast.S_block (SlipScript _)) -> true | _ -> false

    let slip_script = (slip_script, "slip-script")

    let draw (bol : Ast.Bol.t) =
      match bol with
      | `Inline (Ast.S_inline (Hand_drawn _)) -> true
      | _ -> false

    let draw = (draw, "drawing")
    let any = ((fun _ -> true), "anything")
  end

  let handle_id_get (id_map : Id_map.t) val_loc (id, loc) =
    let loc = Diagnosis.loc_of_ploc val_loc loc in
    match Id_map.SMap.find_opt id id_map with
    | None ->
        Diagnosis.add @@ MissingID { id; loc };
        None
    | Some { elem = bol; _ } -> Some (bol, Some loc)

  let handle_id id_map val_loc (id, loc) =
    handle_id_get id_map val_loc (id, loc) |> ignore

  let handle_ids id_map val_loc ids = List.iter (handle_id id_map val_loc) ids

  let targets (is, expected_type) id_map ~args ~val_loc bol =
    let targets =
      match args with
      | `Self -> [ ((bol : Ast.Bol.t :> [ Ast.Bol.t | `External ]), None) ]
      | `Ids ids -> List.filter_map (handle_id_get id_map val_loc) ids
    in
    List.iter
      (fun (bol, id_loc) ->
        match bol with
        | #Ast.Bol.t as bol ->
            if not (is bol) then
              let loc_block = Ast.Bol.text_loc bol in
              let loc_reason =
                Option.value id_loc ~default:(Ast.Bol.text_loc bol)
              in
              Diagnosis.add
              @@ WrongType { loc_reason; loc_block; expected_type }
        | `External -> ())
      targets;
    ()

  let target is id_map ~args ~val_loc bol =
    let args = match args with `Self -> `Self | `Id id -> `Ids [ id ] in
    targets is id_map ~args ~val_loc bol

  let with_target extract_target =
   fun is id_map ~args ~val_loc bol ->
    let args = extract_target args in
    target is id_map ~args ~val_loc bol

  let with_targets extract_targets =
   fun is id_map ~args ~val_loc bol ->
    let args = extract_targets args in
    targets is id_map ~args ~val_loc bol

  let no_constraint _id_map ~args:_ ~val_loc:_ _bol = ()
  let bol_target = target Is.(not slip_script)
  let bol_targets = targets Is.(not slip_script)
  let with_bol_target extract = with_target extract Is.(not slip_script)
  let with_bol_targets extract = with_targets extract Is.(not slip_script)

  (* The action checks *)
  let exec = targets Is.slip_script
  let enter = with_target (fun args -> args.Enter.target) Is.(slip ||| slide)
  let move = with_bol_target
  let up = move (fun args -> args.Up.target)
  let down = move (fun args -> args.Down.target)
  let center = move (fun args -> args.Center.target)
  let scroll = move (fun args -> args.Scroll.target)
  let focus = with_bol_targets (fun args -> args.Focus.target)
  let unfocus = no_constraint
  let set_class = bol_targets
  let unstatic = set_class
  let static = set_class
  let reveal = set_class
  let unreveal = set_class
  let emph = set_class
  let unemph = set_class
  let speaker_note = bol_target
  let play_media = targets Is.playable_media

  let change_page id_map ~args ~val_loc bol =
    List.iter
      (fun (arg : Actions_arguments.Change_page.arg) ->
        target Is.(carousel ||| pdf) id_map ~args:arg.target ~val_loc bol)
      args

  let draw = targets Is.draw
  let clear = targets Is.draw
  let pause = targets Is.any
  let step = no_constraint
end

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
      Check.enter id_map ~args ~val_loc bol;
      (Enter args, kv)
  | Clear_draw ->
      let< args = Clear_draw.parse_args value in
      Check.clear id_map ~args ~val_loc bol;
      (Clear_draw args, kv)
  | Draw ->
      let< args = Draw.parse_args value in
      Check.draw id_map ~args ~val_loc bol;
      (Draw args, kv)
  | Pause ->
      let< args = Pause.parse_args value in
      Check.pause id_map ~args ~val_loc bol;
      (Pause args, kv)
  | Step ->
      let< args = Step.parse_args value in
      Check.step id_map ~args ~val_loc bol;
      (Step args, kv)
  | Up ->
      let< args = Up.parse_args value in
      Check.up id_map ~args ~val_loc bol;
      (Up args, kv)
  | Down ->
      let< args = Down.parse_args value in
      Check.down id_map ~args ~val_loc bol;
      (Down args, kv)
  | Center ->
      let< args = Center.parse_args value in
      Check.center id_map ~args ~val_loc bol;
      (Center args, kv)
  | Scroll ->
      let< args = Scroll.parse_args value in
      Check.scroll id_map ~args ~val_loc bol;
      (Scroll args, kv)
  | Change_page ->
      let< args = Change_page.parse_args value in
      Check.change_page id_map ~args ~val_loc bol;
      (Change_page args, kv)
  | Focus ->
      let< args = Focus.parse_args value in
      Check.focus id_map ~args ~val_loc bol;
      (Focus args, kv)
  | Unfocus ->
      let< args = Unfocus.parse_args value in
      Check.unfocus id_map ~args ~val_loc bol;
      (Unfocus args, kv)
  | Execute ->
      let< args = Execute.parse_args value in
      Check.exec id_map ~args ~val_loc bol;
      (Execute args, kv)
  | Unstatic ->
      let< args = Unstatic.parse_args value in
      Check.unstatic id_map ~args ~val_loc bol;
      (Unstatic args, kv)
  | Static ->
      let< args = Static.parse_args value in
      Check.static id_map ~args ~val_loc bol;
      (Static args, kv)
  | Reveal ->
      let< args = Reveal.parse_args value in
      Check.reveal id_map ~args ~val_loc bol;
      (Reveal args, kv)
  | Unreveal ->
      let< args = Unreveal.parse_args value in
      Check.unreveal id_map ~args ~val_loc bol;
      (Unreveal args, kv)
  | Emph ->
      let< args = Emph.parse_args value in
      Check.emph id_map ~args ~val_loc bol;
      (Emph args, kv)
  | Unemph ->
      let< args = Unemph.parse_args value in
      Check.unemph id_map ~args ~val_loc bol;
      (Unemph args, kv)
  | Speaker_note ->
      let< args = Speaker_note.parse_args value in
      Check.speaker_note id_map ~args ~val_loc bol;
      (Speaker_note args, kv)
  | Play_media ->
      let< args = Play_media.parse_args value in
      Check.play_media id_map ~args ~val_loc bol;
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
          let () = Check.Unknow_attributes.no_unknown_attributes attrs in
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
          let () = Check.Unknow_attributes.no_unknown_attributes attrs in
          match attributes_to_step id_map attrs (`Inline i) with
          | None -> acc
          | Some x -> x :: acc)
    in
    Folder.ret @@ Ast.Folder.continue_inline f i acc
  in
  Ast.Folder.make ~block ~inline ()

let execute ~id_map ast =
  Folder.fold_doc (folder ~id_map) [] ast.Ast.doc |> List.rev
