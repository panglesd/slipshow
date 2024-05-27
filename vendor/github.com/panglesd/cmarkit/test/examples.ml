(* This code is in the public domain *)

(* index.mld *)

let cmark_to_html : strict:bool -> safe:bool -> string -> string =
fun ~strict ~safe md ->
  let doc = Cmarkit.Doc.of_string ~strict md in
  Cmarkit_html.of_doc ~safe doc

let cmark_to_latex : strict:bool -> string -> string =
fun ~strict md ->
  let doc = Cmarkit.Doc.of_string ~strict md in
  Cmarkit_latex.of_doc doc

let cmark_to_commonmark : strict:bool -> string -> string =
fun ~strict md ->
  let doc = Cmarkit.Doc.of_string ~layout:true ~strict md in
  Cmarkit_commonmark.of_doc doc

(* Cmarkit_renderer *)

type Cmarkit.Block.t += Doc of Cmarkit.Doc.t (* 1 *)

let media_link c l =
  let has_ext s ext = String.ends_with ~suffix:ext s in
  let is_video s = List.exists (has_ext s) [".mp4"; ".webm"] in
  let is_audio s = List.exists (has_ext s) [".mp3"; ".flac"] in
  let defs = Cmarkit_renderer.Context.get_defs c in
  match Cmarkit.Inline.Link.reference_definition defs l with
  | Some Cmarkit.Link_definition.Def ((ld, _), _) ->
      let start_tag = match Cmarkit.Link_definition.dest ld with
      | (* Some *) (src, _) when is_video src -> Some ("<video", src)
      | (* Some *) (src, _) when is_audio src -> Some ("<audio", src)
      | (* None | Some *) _ -> None
      in
      begin match start_tag with
      | None -> false (* let the default HTML renderer handle that *)
      | Some (start_tag, src) ->
          (* More could be done with the reference title and link text *)
          Cmarkit_renderer.Context.string c start_tag;
          Cmarkit_renderer.Context.string c {| src="|};
          Cmarkit_html.pct_encoded_string c src;
          Cmarkit_renderer.Context.string c {|" />|};
          true
      end
  | None | Some _ -> false (* let the default HTML renderer that *)

let custom_html =
  let inline c = function
  | Cmarkit.Inline.Image (l, _) -> media_link c l
  | _ -> false (* let the default HTML renderer handle that *)
  in
  let block c = function
  | Doc d ->
      (* It's important to recurse via Cmarkit_renderer.Context.block *)
      Cmarkit_renderer.Context.block c (Cmarkit.Doc.block d); true
  | _ -> false (* let the default HTML renderer handle that *)
  in
  Cmarkit_renderer.make ~inline ~block () (* 2 *)

let custom_html_of_doc ~safe doc =
  let default = Cmarkit_html.renderer ~safe () in
  let r = Cmarkit_renderer.compose default custom_html in (* 3 *)
  Cmarkit_renderer.doc_to_string r doc

(* Cmarkit.Link_reference *)

let wikilink = Cmarkit.Meta.key () (* A meta key to recognize them *)

let make_wikilink label = (* Just a placeholder label definition *)
  let meta = Cmarkit.Meta.tag wikilink (Cmarkit.Label.meta label) in
  Cmarkit.Label.with_meta meta label

let with_wikilinks = function
| `Def _ as ctx -> Cmarkit.Label.default_resolver ctx
| `Ref (_, _, (Some _ as def)) -> def (* As per doc definition *)
| `Ref (_, ref, None) -> Some (make_wikilink ref)

(* Cmarkit.Mapper *)

let set_unknown_code_block_lang ~lang doc =
  let open Cmarkit in
  let default = lang, Meta.none in
  let block m = function
  | Block.Code_block ((cb, _), meta)
    when Option.is_none (Block.Code_block.info_string cb) ->
      let layout = Block.Code_block.layout cb in
      let code = Block.Code_block.code cb in
      let cb = Block.Code_block.make ~layout ~info_string:default code in
      Mapper.ret (Block.Code_block ((cb, (Attributes.empty, Meta.none)), meta))
  | _ ->
      Mapper.default (* let the mapper thread the map *)
  in
  let mapper = Mapper.make ~block () in
  Mapper.map_doc mapper doc

(* Cmarkit.Folder *)

let code_block_langs doc =
  let open Cmarkit in
  let module String_set = Set.Make (String) in
  let block m acc = function
  | Block.Code_block ((cb, _), _) ->
      let acc = match Block.Code_block.info_string cb with
      | None -> acc
      | Some (info, _) ->
          match Block.Code_block.language_of_info_string info with
          | None -> acc
          | Some (lang, _) -> String_set.add lang acc
      in
      Folder.ret acc
  | _ ->
      Folder.default (* let the folder thread the fold *)
  in
  let folder = Folder.make ~block () in
  let langs = Folder.fold_doc folder String_set.empty doc in
  String_set.elements langs

(* Cmarkit_html *)

let html_doc_of_md ?(lang = "en") ~title ~safe md =
  let doc = Cmarkit.Doc.of_string md in
  let r = Cmarkit_html.renderer ~safe () in
  let buffer_add_doc = Cmarkit_renderer.buffer_add_doc r in
  let buffer_add_title = Cmarkit_html.buffer_add_html_escaped_string in
  Printf.kbprintf Buffer.contents (Buffer.create 1024)
{|<html lang="%s">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>%a</title>
</head>
<body>
%a</body>
</html>|}
    lang buffer_add_title title buffer_add_doc doc

(* Cmarkit_latex *)

let latex_doc_of_md ?(title = "") md =
  let doc = Cmarkit.Doc.of_string md in
  let r = Cmarkit_latex.renderer () in
  let buffer_add_doc = Cmarkit_renderer.buffer_add_doc r in
  let buffer_add_title = Cmarkit_latex.buffer_add_latex_escaped_string in
  let maketitle = if title = "" then "" else {|\maketitle|} in
  Printf.kbprintf Buffer.contents (Buffer.create 1024)
{|\documentclass{article}

\usepackage{graphicx}
\usepackage{enumitem}
\usepackage{listings}
\usepackage{hyperref}
\usepackage[normalem]{ulem}
\usepackage[scaled=0.8]{beramono}
\usepackage{fontspec}

\lstset{
  columns=[c]fixed,
  basicstyle=\small\ttfamily,
  keywordstyle=\bfseries,
  upquote=true,
  commentstyle=\slshape,
  breaklines=true,
  showstringspaces=false}

\lstdefinelanguage{ocaml}{language=[objective]caml,
  literate={'"'}{\textquotesingle "\textquotesingle}3
            {'\\"'}{\textquotesingle \textbackslash"\textquotesingle}4,
}

\title{%a}
\begin{document}
%s
%a
\end{document}|} buffer_add_title title maketitle buffer_add_doc doc
