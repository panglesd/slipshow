open Cmarkit

let of_cmarkit resolve_images =
  let block m = function
    | Block.Block_quote ((bq, (attrs, meta2)), meta) ->
        if Attributes.mem "blockquote" attrs then Mapper.default
        else
          let b = Block.Block_quote.block bq in
          let b =
            match Mapper.map_block m b with None -> Block.empty | Some b -> b
          in
          let attrs = Mapper.map_attrs m attrs in
          Mapper.ret (Ast.Div ((b, (attrs, meta2)), meta))
    | Block.Code_block ((cb, (attrs, meta)), meta2) ->
        let ret =
          match Block.Code_block.info_string cb with
          | None -> Mapper.default
          | Some (info, _) -> (
              match Block.Code_block.language_of_info_string info with
              | Some ("slip-script", _) ->
                  Mapper.ret
                    (Ast.SlipScript
                       ((cb, (Mapper.map_attrs m attrs, meta)), meta2))
              | _ -> Mapper.default)
        in
        ret
    | _ -> Mapper.default
  in
  let inline i = function
    | Inline.Image ((l, (attrs, meta2)), meta) ->
        let text = Inline.Link.text l in
        let reference =
          match Inline.Link.reference l with
          | `Ref _ as r -> r
          | `Inline ((ld, attrs), meta) ->
              let label, layout, defined_label, (dest, meta_dest), title =
                Link_definition.
                  (label ld, layout ld, defined_label ld, dest ld, title ld)
              in
              let dest =
                match resolve_images dest with
                | Ast.Remote s -> s
                | Local { mime_type; content } ->
                    let mime_type = Option.value ~default:"" mime_type in
                    let base64 = Base64.encode_string content in
                    Format.sprintf "data:%s;base64,%s" mime_type base64
              in
              let dest = (dest, meta_dest) in
              let ld =
                Link_definition.make ~layout ~defined_label ?label ~dest ?title
                  ()
              in
              `Inline ((ld, attrs), meta)
        in
        let l = Inline.Link.make text reference in
        let attrs = Mapper.map_attrs i attrs in
        Mapper.ret (Inline.Image ((l, (attrs, meta2)), meta))
    | _ -> Mapper.default
  in
  let attrs = function
    | `Kv (("up", m), v) -> Some (`Kv (("up-at-unpause", m), v))
    | `Kv (("center", m), v) -> Some (`Kv (("center-at-unpause", m), v))
    | `Kv (("down", m), v) -> Some (`Kv (("down-at-unpause", m), v))
    | `Kv (("exec", m), v) -> Some (`Kv (("exec-at-unpause", m), v))
    | x -> Some x
  in
  Ast.Mapper.make ~block ~inline ~attrs ()
