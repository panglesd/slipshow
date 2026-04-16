let ast : Slipshow.Ast.t option ref = ref None
let set_ast x = ast := Some x

let pos_in_textloc ?(permissive = false) ~(pos : Linol_lwt.Position.t) ~loc () =
  let ( <? ) = if permissive then ( <= ) else ( < ) in
  let range = loc in
  let range = Diagnostic.linoloc_of_textloc range in
  Format.eprintf "is %d:%d in %d:%d -> %d:%d?\n" pos.line pos.character
    range.start.line range.start.character range.end_.line range.end_.character;
  let res =
    ((range.start.line = pos.line && range.start.character <= pos.character)
    || range.start.line < pos.line)
    && ((range.end_.line = pos.line && pos.character <? range.end_.character)
       || pos.line < range.end_.line)
  in
  Format.eprintf "%s\n%!" (if res then "yes" else "no");
  res

let pos_in ~(pos : Linol_lwt.Position.t) ~meta =
  let loc = Cmarkit.Meta.textloc meta in
  pos_in_textloc ~pos ~loc

let pos_in_inline inline ~pos =
  let meta = Slipshow.Ast.Utils.Inline.meta inline in
  let attrs = Slipshow.Ast.Utils.Inline.get_attribute inline in
  let is_in_attrs =
    match attrs with
    | None -> false
    | Some (_, (_, meta)) -> pos_in ~pos ~meta ()
  in
  is_in_attrs || pos_in ~pos ~meta ()

let pos_in_block block ~pos =
  let meta = Slipshow.Ast.Utils.Block.meta block in
  let attrs = Slipshow.Ast.Utils.Block.get_attribute block in
  let is_in_attrs =
    match attrs with
    | None -> false
    | Some (_, (_, meta)) -> pos_in ~pos ~meta ()
  in
  is_in_attrs || pos_in ~pos ~meta ()

open Cmarkit

type attribute_trace =
  | Key of string node * Attributes.value node option
  | Value of string node * Attributes.value node
  | Class of string node
  | Id of string node

type inline_trace = Inline.t list
type block_trace = Block.t list

type trace = {
  attribute : attribute_trace option;
  inline : inline_trace;
  block : block_trace;
}

let enter_attrs acc pos attrs =
  let pos_in ~meta = pos_in ~permissive:true ~pos ~meta () in
  let kv =
    let kv = Cmarkit.Attributes.kv_attributes attrs in
    List.find_map
      (function
        | k, Some ((_, meta) as v) when pos_in ~meta -> Some (Value (k, v))
        | ((_, meta) as k), v when pos_in ~meta -> Some (Key (k, v))
        | _ -> None)
      kv
  in
  let class_ =
    let classes = Cmarkit.Attributes.class' attrs in
    List.find_map
      (function
        | (_, meta) as v when pos_in ~meta -> Some (Class v) | _ -> None)
      classes
  in
  let id =
    match Cmarkit.Attributes.id attrs with
    | Some ((_, meta) as id) when pos_in ~meta -> Some (Id id)
    | _ -> None
  in
  let attribute =
    match (kv, class_, id) with
    | (Some _ as s), _, _ | _, (Some _ as s), _ | _, _, s -> s
  in
  { acc with attribute }

let rec enter_inline acc pos (inline : Cmarkit.Inline.t) =
  let acc = { acc with inline = inline :: acc.inline } in
  let may_enter i =
    if pos_in_inline ~pos i then enter_inline acc pos i else acc
  in
  let attrs = Slipshow.Ast.Utils.Inline.get_attribute inline in
  let attrs =
    match attrs with
    | Some (_, (attrs, meta)) when pos_in ~pos ~meta () ->
        Some (enter_attrs acc pos attrs)
    | _ -> None
  in
  (fun f -> match attrs with Some x -> x | None -> f ()) @@ fun () ->
  let open Cmarkit.Inline in
  match inline with
  (* Standard Cmarkit nodes *)
  | Ext_math_span _ | Raw_html _ | Text _ | Autolink _ | Break _ | Code_span _
    ->
      acc
  | Strong_emphasis ((em, _), _) | Emphasis ((em, _), _) ->
      let i = Emphasis.inline em in
      enter_inline acc pos i
  | Inlines (is, _) -> (
      let next = List.find_opt (pos_in_inline ~pos) is in
      match next with None -> acc | Some i -> enter_inline acc pos i)
  | Image ((link, _), _) | Link ((link, _), _) ->
      let i = Link.text link in
      may_enter i
  (* Extension Cmarkit nodes *)
  | Ext_strikethrough ((strk, _), _) ->
      let i = Strikethrough.inline strk in
      may_enter i
  | Ext_attrs (attr_span, _) ->
      let i = Attributes_span.content attr_span in
      may_enter i
  (* Slipshow nodes *)
  | Slipshow.Ast.S_inline i -> (
      match i with
      | Hand_drawn m | Image m | Svg m | Video m | Audio m | Pdf m ->
          let (link, _), _ = m.origin in
          let i = Link.text link in
          may_enter i)
  | _ -> acc

(* let get_leave_inline pos (inline : Cmarkit.Inline.t) = *)
(*   let meta = Slipshow.Ast.Utils.Inline.meta inline in *)
(*   if pos_in ~pos ~meta then enter_inline pos inline else None *)

let rec enter_block acc pos (block : Cmarkit.Block.t) =
  let open Cmarkit.Block in
  let attrs = Slipshow.Ast.Utils.Block.get_attribute block in
  let attrs =
    match attrs with
    | Some (_, (attrs, meta)) when pos_in ~pos ~meta () ->
        Some (enter_attrs acc pos attrs)
    | _ -> None
  in
  (fun f -> match attrs with Some x -> x | None -> f ()) @@ fun () ->
  let acc = { acc with block = block :: acc.block } in
  match block with
  | Blank_line _ | Code_block _ | Thematic_break _ | Html_block _
  | Ext_math_block _ ->
      acc
  | Ext_footnote_definition _ | Ext_table _ | Link_reference_definition _
  | Ext_attribute_definition _ ->
      (* TODO *)
      acc
  | Ext_standalone_attributes (attrs, _) -> enter_attrs acc pos attrs
  | Heading ((h, _attrs), _) ->
      let inline = Heading.inline h in
      if pos_in_inline ~pos inline then enter_inline acc pos inline else acc
  | Block_quote ((bq, _attrs), _) ->
      let b = Block_quote.block bq in
      if pos_in_block ~pos b then enter_block acc pos b else acc
  | Blocks (bs, _) -> (
      let next = List.find_opt (pos_in_block ~pos) bs in
      match next with None -> acc | Some b -> enter_block acc pos b)
  | List ((l, _attrs), _) ->
      let lis = List'.items l in
      let ( let+ ) x f = match x with None -> acc | Some x -> f x in
      let+ li, _ = List.find_opt (fun (_, meta) -> pos_in ~pos ~meta ()) lis in
      let block = List_item.block li in
      if pos_in_block block ~pos then enter_block acc pos block else acc
  | Paragraph ((p, _attrs), _) ->
      prerr_endline "entering paragraph";
      let inline = Paragraph.inline p in
      if pos_in_inline ~pos inline then enter_inline acc pos inline else acc
  | Slipshow.Ast.S_block b -> (
      match b with
      | Included _ -> acc (* TODO: do *)
      | Slip ((block, _), _) | Div ((block, _), _) ->
          if pos_in_block block ~pos then enter_block acc pos block else acc
      | Slide ((slide, _), _) ->
          (* TODO: title *)
          let block = slide.content in
          if pos_in_block block ~pos then enter_block acc pos block else acc
      | MermaidJS _ | SlipScript _ -> acc
      | Carousel ((bs, _), _) -> (
          let next = List.find_opt (pos_in_block ~pos) bs in
          match next with None -> acc | Some b -> enter_block acc pos b))
  | _ -> assert false

let get_leave pos doc =
  let acc = { attribute = None; inline = []; block = [] } in
  let block = Cmarkit.Doc.block doc in
  if pos_in_block block ~pos then enter_block acc pos block else acc

let get_target pos (action_plan : Slipshow.Action_plan.t) =
  List.find_map
    (fun { Slipshow.Action_plan.actions; attrs = _, meta; _ } ->
      if not @@ pos_in ~pos ~meta () then None
      else
        List.find_map
          (fun (arg, (_, value)) ->
            Option.bind value @@ fun (_, meta) ->
            let loc = Cmarkit.Meta.textloc meta in
            if not @@ pos_in_textloc ~permissive:true ~pos ~loc () then None
            else
              let targets = Slipshow.Action_plan.targets arg in
              List.find_map
                (fun (t, ploc) ->
                  let loc = Diagnosis.loc_of_ploc loc ploc in
                  if pos_in_textloc ~permissive:true ~pos ~loc () then Some t
                  else None)
                targets)
          actions)
    action_plan
