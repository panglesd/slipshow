module RenderAttrs = struct
  module C = Cmarkit_renderer.Context
  open Cmarkit

  let add_attr c (key, value) =
    match value with
    | Some value -> C.string c (" " ^ key ^ "=" ^ value)
    | None -> C.string c (" " ^ key)

  let add_attrs c ?(include_id = true) attrs =
    let kv_attrs =
      let kv_attrs = Cmarkit.Attributes.kv_attributes attrs in
      List.map
        (fun ((k, _), v) ->
          let v = match v with None -> None | Some (v, _) -> Some v in
          (k, v))
        kv_attrs
    in
    let class' =
      let class' = Cmarkit.Attributes.class' attrs in
      let class' = List.map (fun (c, _) -> c) class' in
      match class' with
      | [] -> []
      | _ -> [ ("class", Some ("\"" ^ String.concat " " class' ^ "\"")) ]
    in
    let id =
      let id = Cmarkit.Attributes.id attrs in
      match id with
      | Some (id, _) when include_id -> [ ("id", Some ("\"" ^ id ^ "\"")) ]
      | _ -> []
    in
    let attrs = id @ class' @ kv_attrs in
    List.iter (add_attr c) attrs

  let open_block ?(with_newline = true) c tag attrs =
    C.string c "<";
    C.string c tag;
    add_attrs c attrs;
    C.string c ">";
    if with_newline then C.string c "\n"

  let close_block ?(with_newline = true) c tag =
    C.string c "</";
    C.string c tag;
    C.string c ">";
    if with_newline then C.string c "\n"

  let in_block c ?(with_newline = true) tag attrs f =
    open_block ~with_newline c tag attrs;
    f ();
    close_block ~with_newline c tag

  let with_attrs c ?(with_newline = true) attrs f =
    if Attributes.is_empty attrs then f ()
    else in_block c ~with_newline "div" attrs f

  let with_attrs_span c ?(with_newline = true) attrs f =
    if Attributes.is_empty attrs then f ()
    else in_block c ~with_newline "span" attrs f

  let block_lines c = function
    (* newlines only between lines *)
    | [] -> ()
    | (l, _) :: ls ->
        let line c (l, _) =
          C.byte c '\n';
          C.string c l
        in
        C.string c l;
        List.iter (line c) ls
end

let custom_html_renderer =
  let open Cmarkit_renderer in
  let open Cmarkit in
  let open Cmarkit_html in
  let default = renderer ~safe:false () in
  let custom_html =
    let inline c = function
      | Inline.Text ((t, (attrs, _)), _) ->
          (* Put text inside spans to be able to apply styles on them *)
          Context.string c "<span";
          add_attrs c attrs;
          Context.byte c '>';
          html_escaped_string c t;
          Context.string c "</span>";
          true
          (* | Inline.Ext_attrs (attrs_span, _) ->    Context.string c "yooooo"; let (attrs, _) = Inline.Attributes_span.attrs attrs_span and i = Inline.Attributes_span.content attrs_span in     RenderAttrs.with_attrs_span c attrs (fun () -> Context.inline c i); *)
          (*     true *)
      | _ -> false (* let the default HTML renderer handle that *)
    in
    let block c = function
      | Ast.Included ((b, (attrs, _)), _) | Ast.Div ((b, (attrs, _)), _) ->
          RenderAttrs.with_attrs c attrs (fun () -> Context.block c b);
          true
      | Ast.Slide ((slide, (attrs, _)), _) ->
          let () =
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slipshow-rescaler", Meta.none) ] ())
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.add_class attrs ("slide", Meta.none))
            @@ fun () -> Context.block c slide
          in
          true
      | Ast.Slip ((slip, (attrs, _)), _) ->
          let () =
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slipshow-rescaler", Meta.none) ] ())
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.add_class attrs ("slip", Meta.none))
            @@ fun () ->
            RenderAttrs.in_block c "div"
              (Attributes.make ~class':[ ("slip-body", Meta.none) ] ())
            @@ fun () -> Context.block c slip
          in
          true
      | Ast.SlipScript ((cb, (attrs, _)), _) ->
          let attrs =
            Attributes.add ("type", Meta.none)
              (Some ("slip-script", Meta.none))
              attrs
          in
          RenderAttrs.in_block c "script" attrs (fun () ->
              RenderAttrs.block_lines c (Block.Code_block.code cb));
          true
      | _ -> false
    in
    make ~inline ~block ()
  in
  compose default custom_html
