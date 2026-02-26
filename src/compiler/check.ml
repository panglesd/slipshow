open Cmarkit
module M = Map.Make (String)

module Is = struct
  let carousel_or_pdf (bol : Ast.Bol.t) =
    match bol with
    | `Block (Ast.S_block (Carousel _)) -> true
    | `Inline (Ast.S_inline (Pdf _)) -> true
    | _ -> false

  let carousel_or_pdf = (carousel_or_pdf, "carousel or pdf")

  let playable_media (bol : Ast.Bol.t) =
    match bol with
    | `Inline (Ast.S_inline (Video _ | Audio _)) -> true
    | _ -> false

  let playable_media = (playable_media, "video or audio")

  let slip_script (bol : Ast.Bol.t) =
    match bol with `Block (Ast.S_block (SlipScript _)) -> true | _ -> false

  let slip_script = (slip_script, "slip-script")

  let draw (bol : Ast.Bol.t) =
    match bol with `Inline (Ast.S_inline (Hand_drawn _)) -> true | _ -> false

  let draw = (draw, "drawing")
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
  let loc = Diagnosis.loc_of_ploc val_loc loc in
  match M.find_opt id id_map with
  | None ->
      Diagnosis.add @@ MissingID { id; loc };
      None
  | Some (_, bol, _) -> Some (bol, Some loc)

let handle_id id_map val_loc (id, loc) =
  handle_id_get id_map val_loc (id, loc) |> ignore

let handle_ids id_map val_loc ids = List.iter (handle_id id_map val_loc) ids

let check_targets (is, expected_type) id_map bol val_loc targets =
  let targets =
    match targets with
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
            Diagnosis.add @@ WrongType { loc_reason; loc_block; expected_type }
      | `External -> ())
    targets;
  ()

let check_target is id_map bol val_loc target =
  let targets = match target with `Self -> `Self | `Id id -> `Ids [ id ] in
  check_targets is id_map bol val_loc targets

let exec id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Execute) attrs @@ fun args val_loc ->
  check_targets Is.slip_script id_map block_or_inline val_loc args

type id_map = ((string * Meta.t) * [ Ast.Bol.t | `External ] * Meta.t) M.t

let move (module A : Actions_arguments.Move) (id_map : id_map) attrs
    (_block_or_inline : Ast.Bol.t) =
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
    (_block_or_inline : Ast.Bol.t) =
  parse_args (module A) attrs @@ fun args val_loc ->
  match args with `Self -> () | `Ids ids -> handle_ids id_map val_loc ids

let unstatic = set_class (module Actions_arguments.Unstatic)
let static = set_class (module Actions_arguments.Static)
let reveal = set_class (module Actions_arguments.Reveal)
let unreveal = set_class (module Actions_arguments.Unreveal)
let emph = set_class (module Actions_arguments.Emph)
let unemph = set_class (module Actions_arguments.Unemph)

let speaker_note id_map attrs _block_or_inline =
  parse_args (module Actions_arguments.Speaker_note) attrs
  @@ fun args val_loc ->
  match args with `Self -> () | `Id id -> handle_id id_map val_loc id

let play_media id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Play_media) attrs @@ fun args val_loc ->
  check_targets Is.playable_media id_map block_or_inline val_loc args

let change_page id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Change_page) attrs @@ fun args val_loc ->
  List.iter
    (fun (arg : Actions_arguments.Change_page.arg) ->
      check_target Is.carousel_or_pdf id_map block_or_inline val_loc arg.target)
    args

let draw id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Draw) attrs @@ fun args val_loc ->
  check_targets Is.draw id_map block_or_inline val_loc args

let clear_draw id_map attrs block_or_inline =
  parse_args (module Actions_arguments.Clear_draw) attrs @@ fun args val_loc ->
  check_targets Is.draw id_map block_or_inline val_loc args

let pause id_map attrs _block_or_inline =
  parse_args (module Actions_arguments.Pause) attrs @@ fun args val_loc ->
  match args with `Self -> () | `Ids ids -> handle_ids id_map val_loc ids

module SSet = Set.Make (String)

(* To get this list of all valid html attributes, go to
   [https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes], get
   the [tbody] DOM element of the list table, and run:

   {[
     Array.from(temp0.querySelectorAll("tr>td:first-child")).map((e) => {return e.innerText})
   ]}

   Right click, copy object, paste it, and then:
   - Remove the "Deprecated" and "Experimental" flags
   - Remove the data-* entry
*)
let all_attributes =
  [
    "accept";"accept-charset";"accesskey";"action";"align";"allow";"alpha";"alt";"as";"async";"autocapitalize";"autocomplete";"autoplay";"background";"bgcolor";"border";"capture";"charset";"checked";"cite";"class";"color";"colorspace";"cols";"colspan";"content";"contenteditable";"controls";"coords";"crossorigin";"csp";"data";"datetime";"decoding";"default";"defer";"dir";"dirname";"disabled";"download";"draggable";"enctype";"enterkeyhint";"elementtiming";"fetchpriority";"for";"form";"formaction";"formenctype";"formmethod";"formnovalidate";"formtarget";"headers";"height";"hidden";"high";"href";"hreflang";"http-equiv";"id";"integrity";"inputmode";"ismap";"itemprop";"kind";"label";"lang";"language";"loading";"list";"loop";"low";"max";"maxlength";"minlength";"media";"method";"min";"multiple";"muted";"name";"novalidate";"open";"optimum";"pattern";"ping";"placeholder";"playsinline";"poster";"preload";"readonly";"referrerpolicy";"rel";"required";"reversed";"role";"rows";"rowspan";"sandbox";"scope";"selected";"shape";"size";"sizes";"slot";"span";"spellcheck";"src";"srcdoc";"srclang";"srcset";"start";"step";"style";"summary";"tabindex";"target";"title";"translate";"type";"usemap";"value";"width";"wrap";
  ] |> SSet.of_list
 [@@ocamlformat "disable"]

let all_actions =
  List.map
    (fun (module A : Actions_arguments.S) -> A.on)
    Actions_arguments.all_actions
  |> SSet.of_list

let all_special = Special_attrs.all_attrs |> SSet.of_list

let check_attribute key loc =
  if SSet.mem key all_actions then ()
  else if SSet.mem key all_special then ()
  else if SSet.mem key all_attributes then ()
  else if String.starts_with ~prefix:"data-" key then ()
  else if String.starts_with ~prefix:"children:" key then ()
  else Diagnosis.add (UnknownAttribute { attr = key; loc })

let no_unknown_attributes _id_map attrs _block_or_inline =
  let kv = Attributes.kv_attributes attrs in
  List.iter
    (fun ((key, meta), _value) ->
      check_attribute key (Cmarkit.Meta.textloc meta))
    kv

let all_checks =
  [
    clear_draw;
    draw;
    change_page;
    play_media;
    pause;
    speaker_note;
    unstatic;
    static;
    reveal;
    unreveal;
    emph;
    unemph;
    focus;
    unfocus;
    up;
    down;
    center;
    scroll;
    enter;
    exec;
    no_unknown_attributes;
  ]
