type node = {
  attrs : Cmarkit.Attributes.t;
  name : string;
  children : node list;
}

let v ?(attrs = Cmarkit.Attributes.empty) name children =
  { attrs; name; children }

let pp_attrs fmt attrs =
  let attrs_kv =
    Cmarkit.Attributes.kv_attributes attrs
    |> List.map (function
         | (x, _), None -> (x, None)
         | (x, _), Some (y, _) -> (x, Some y.Cmarkit.Attributes.v))
  in
  let attrs_class =
    let class' = Cmarkit.Attributes.class' attrs in
    match class' with
    | [] -> []
    | class' -> [ ("class", Some (String.concat " " (class' |> List.map fst))) ]
  in
  let attrs_id =
    let id = Cmarkit.Attributes.id attrs in
    match id with None -> [] | Some (id, _) -> [ ("id", Some id) ]
  in
  let attrs = List.concat [ attrs_id; attrs_class; attrs_kv ] in
  let open Format in
  if attrs = [] then ()
  else
    let pp_pair fmt (k, v) =
      match v with
      | None -> fprintf fmt "%s" k
      | Some v -> fprintf fmt "%s=%S" k v
    in
    fprintf fmt " {@[<h>%a@]}"
      (pp_print_list ~pp_sep:(fun fmt () -> fprintf fmt ";@ ") pp_pair)
      attrs

let rec pp_node fmt node =
  let open Format in
  fprintf fmt "@[<hv 2>(%s" node.name;
  fprintf fmt "%a" pp_attrs node.attrs;
  (match node.children with
  | [] -> ()
  | children ->
      fprintf fmt "@ ";
      pp_print_list
        ~pp_sep:(fun fmt () -> fprintf fmt "@ ")
        pp_node fmt children);
  fprintf fmt ")@]"

let rec of_ast ast =
  let open Cmarkit.Block in
  match ast with
  | Blank_line _ -> v "blank line" []
  | Block_quote ((c, (attrs, _)), _) ->
      let c = of_ast (Block_quote.block c) in
      v ~attrs "block_quote" [ c ]
  | Blocks (t, _) -> v "blocks" (List.map of_ast t)
  | Code_block ((_, (attrs, _)), _) -> v ~attrs "code block" []
  | Heading ((_, (attrs, _)), _) -> v ~attrs "heading" []
  | Html_block ((_, (attrs, _)), _) -> v ~attrs "html block" []
  | Link_reference_definition _ -> v "link ref" []
  | List ((l, (attrs, _)), _) ->
      let t = List'.items l |> List.map (fun (x, _) -> List_item.block x) in
      v ~attrs "list" (List.map of_ast t)
  | Paragraph ((_, (attrs, _)), _) -> v ~attrs "paragraph" []
  | Thematic_break _ -> v "thematic break" []
  | Ast.Included ((c, (attrs, _)), _) ->
      let c = of_ast c in
      v ~attrs "included" [ c ]
  | Ast.Div ((c, (attrs, _)), _) ->
      let c = of_ast c in
      v ~attrs "div" [ c ]
  | Ast.Slide ((c, (attrs, _)), _) ->
      let c = of_ast c.content in
      v ~attrs "slide" [ c ]
  | Ast.Slip ((c, (attrs, _)), _) ->
      let c = of_ast c in
      v ~attrs "slip" [ c ]
  | Ast.HSlip ((c, (attrs, _)), _) ->
      let c = List.map of_ast c in
      v ~attrs "h-slip" c
  | Ast.SlipScript ((_, (attrs, _)), _) -> v ~attrs "slide" []
  | Ast.Carousel ((c, (attrs, _)), _) ->
      let c = List.map of_ast c in
      v ~attrs "carousel" c
  | _ -> v "not supported" []
