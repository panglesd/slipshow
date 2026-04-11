open Actions_arguments

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
    match bol with `Inline (Ast.S_inline (Hand_drawn _)) -> true | _ -> false

  let draw = (draw, "drawing")
  let any = ((fun _ -> true), "anything")
end

let get_id (id_map : Id_map.t) val_loc (id, loc) =
  let loc = Diagnosis.loc_of_ploc val_loc loc in
  match Id_map.SMap.find_opt id id_map with
  | None ->
      Diagnosis.add @@ MissingID { id; loc };
      None
  | Some { elem = bol; _ } -> Some (bol, Some loc)

let targets (is, expected_type) id_map ~args ~val_loc bol =
  let targets =
    match args with
    | `Self -> [ ((bol : Ast.Bol.t :> [ Ast.Bol.t | `External ]), None) ]
    | `Ids ids -> List.filter_map (get_id id_map val_loc) ids
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
            Diagnosis.add @@ WrongType { loc_reason; loc_block; expected_type }
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
