(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open B00_std
open Result.Syntax

type arg = { n : string; type' : string; optional : bool }
type func =
  { name : string; args : arg list; ret : string; version : int; }

type funcs = func list String.Map.t

let cleanup_funcs funcs =
  (* Some dupes are not overloadings *)
  let find_dupes = function
  | [f;f'] as funcs ->
      if f.version <> f'.version && f.args = f'.args
      then (if f.version < f'.version then [f] else [f'])
      else funcs
  | funcs -> funcs
  in
  String.Map.map find_dupes funcs

let ocaml_name jname = (* uncamlcase, lowercase *)
  let is_upper c = 'A' <= c && c <= 'Z' in
  let is_digit c = '0' <= c && c <= '9'  in
  let buf = Buffer.create (String.length jname) in
  let last_up = ref true (* avoids prefix by _ *) in
  for i = 0 to String.length jname - 1 do
    if is_upper jname.[i] &&
       not (!last_up) &&
       not (is_digit (jname.[i - 1])) (* maps eg 2D to 2d not 2_d *)
    then (Buffer.add_char buf '_'; last_up := true)
    else (last_up := false);
    Buffer.add_char buf (Char.lowercase_ascii jname.[i]);
  done;
  Buffer.contents buf

let parse_ret i l = match String.cut_left " " l with
| None -> B00_lines.err i "%S: cannot parse return type" l
| Some (ret, rest) -> ret, (String.trim rest)

let parse_name i l = match String.cut_left "(" l with
| None -> B00_lines.err i "%S: cannot parse function name" l
| Some (n, args) ->
    String.trim n, String.subrange ~last:(String.length args - 2) args

let parse_args i args =
  if args = "" then [] else
  let name n = match String.trim n with
  | "type" -> "type'" | "end" -> "end'" (* don't clash with OCaml keywords. *)
  | s -> s
  in
  let parse_arg i arg = match String.cut_left " " (String.trim arg) with
  | None -> B00_lines.err i "%S: cannot parse argument" arg
  | Some (t,n) ->
      match String.trim t with
      | "optional" ->
          begin match String.cut_left " " (String.trim n) with
          | None -> B00_lines.err i "%S: cannot parse argument" arg
          | Some (t, n) -> { n = name n; type' = t; optional = true }
          end
      | t -> { n = name n; type' = t; optional = false }
  in
  List.map (parse_arg i) (String.cuts_left ~sep:"," args)

let parse_func i l = match String.cut_left ";" l with
| Some (rest, ("1" | "2" as v)) ->
    let version = if v = "1" then 1 else 2 in
    let ret, rest = parse_ret i rest in
    let name, args = parse_name i rest in
    let args = parse_args i args in
    { name; args; ret; version }
| None | _ -> B00_lines.err i "%S: cannot parse" l

let parse_funcs ~file data =
  let add_line i line acc = match line with
  | "" -> acc
  | l ->
      let f = parse_func i line in
      String.Map.add_to_list f.name f acc
  in
  Result.map cleanup_funcs (B00_lines.fold ~file data add_line String.Map.empty)

let dump funcs =
  let opt_arg a = if a.optional then " option" else "" in
  let out_arg a = Printf.sprintf "(%s : %s%s)" a.n a.type' (opt_arg a)  in
  let out_args args = String.concat " " (List.map out_arg args) in
  let out_func f =
      Printf.printf "V:%d R:%s N:%s/%s A:%s\n"
      f.version f.ret f.name (ocaml_name f.name) (out_args f.args)
  in
  let out_funcs fname funs () =
    if List.length funs <> 1 then Printf.printf "%s: OVERLOADED\n" fname;
    List.iter out_func funs
  in
  String.Map.fold out_funcs funcs ()

let otype fname = function
| "void" -> "unit"
| "GLenum" -> "enum"
| "sequence<GLenum>" -> "enum list"
| "GLboolean" -> "bool"
| "GLbitfield" | "GLbyte" | "GLshort" | "GLint" | "GLsizei" | "GLintptr"
| "GLsizeiptr" | "GLubyte" | "GLushort" | "GLuint" | "GLint64" | "GLuint64" ->
    "int"
| "sequence<GLint>" | "sequence<GLuint>" | "sequence<GLuint>?"-> "int list"
| "GLfloat" | "GLclampf" -> "float"
  (* The nullables are not always meaningful we can adjust signatures
     later if we hinder functionality. *)
| "WebGLBuffer" | "WebGLBuffer?" -> "buffer"
| "WebGLFramebuffer" | "WebGLFramebuffer?" -> "framebuffer"
| "WebGLProgram" | "WebGLProgram?" -> "program"
| "WebGLQuery" | "WebGLQuery?" -> "query"
| "WebGLRenderbuffer" | "WebGLRenderbuffer?" -> "renderbuffer"
| "WebGLSampler" | "WebGLSampler?" -> "sampler"
| "WebGLShader" | "WebGLShader?" -> "shader"
| "sequence<WebGLShader>?" -> "shader list"
| "WebGLSync" | "WebGLSync?" -> "sync"
| "WebGLTexture" | "WebGLTexture?" -> "texture"
| "WebGLTransformFeedback" | "WebGLTransformFeedback?" -> "transform_feedback"
| "WebGLUniformLocation" | "WebGLUniformLocation?" -> "uniform_location"
| "WebGLVertexArrayObject" | "WebGLVertexArrayObject?" -> "vertex_array_object"
| "WebGLActiveInfo" | "WebGLActiveInfo?" -> "Active_info.t"
| "WebGLShaderPrecisionFormat" | "WebGLShaderPrecisionFormat?" ->
    "Shader_precision_format.t"
| "Float32List" -> "Tarray.float32"
| "Uint32List" -> "Tarray.uint32"
| "Int32List" -> "Tarray.int32"
| "ArrayBufferView" | "ArrayBufferView?" -> "('a, 'b) Tarray.t"
| "BufferSource?" | "BufferSource" -> "Tarray.Buffer.t"
| "TexImageSource" -> "Tex_image_source.t"
| "DOMString" | "DOMString?" -> "Jstr.t"
| "sequence<DOMString>" -> "Jstr.t list"
| "any" -> "Jv.t"
| t -> Printf.eprintf "%s: %S unknown\n" fname t; "todo"

let func_link func =
  let base = match func.version = 1 with
  | true ->
      "https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/"
  | false ->
      "https://developer.mozilla.org/en-US/docs/Web/API/WebGL2RenderingContext/"
  in
  Printf.sprintf "%s%s" base func.name

let func_mli func =
  let fname = ocaml_name func.name in
  let arg_type { type'; _ } = otype func.name type' in
  (* We drop optional arguments *)
  let args = List.filter (fun a -> not a.optional) func.args in
  let args_sig = match args with
  | [] -> ""
  | args -> " -> " ^ String.concat " -> " (List.map arg_type args)
  in
  let ret = otype func.name func.ret in
  let syn = match args with
  | [] -> ""
  | args -> String.concat " " (List.map (fun {n; _} -> n) args)
  in
  Format.printf "  @[<v>@[val %s : t%s -> %s@]@,\
                        @[(** {{:%s}[%s]}[ c%s] *)@]@,@]@."
    fname args_sig ret (func_link func) func.name syn

let type_of_jv fname = function
| "void" -> "ignore"
| "GLboolean" -> "Jv.to_bool"
| "DOMString" | "DOMString?" -> "Jv.to_jstr"
| "sequence<GLuint>?" -> "Jv.to_list Jv.to_int"
| "sequence<WebGLShader>?" -> "Jv.to_jv_list"
| "GLenum" | "GLbitfield" | "GLbyte" | "GLshort" | "GLint" | "GLsizei"
| "GLintptr" | "GLsizeiptr" | "GLubyte" | "GLushort" | "GLuint" | "GLint64"
| "GLuint64" -> "Jv.to_int"
| "GLfloat" | "GLclampf" -> "Jv.to_float"
| "WebGLBuffer" | "WebGLBuffer?"
| "WebGLFramebuffer" | "WebGLFramebuffer?"
| "WebGLProgram" | "WebGLProgram?"
| "WebGLQuery" | "WebGLQuery?"
| "WebGLRenderbuffer" | "WebGLRenderbuffer?"
| "WebGLSampler" | "WebGLSampler?"
| "WebGLShader" | "WebGLShader?"
| "WebGLSync" | "WebGLSync?"
| "WebGLTexture" | "WebGLTexture?"
| "WebGLTransformFeedback" | "WebGLTransformFeedback?"
| "WebGLUniformLocation" | "WebGLUniformLocation?"
| "WebGLVertexArrayObject" | "WebGLVertexArrayObject?"
| "WebGLActiveInfo" | "WebGLActiveInfo?"
| "WebGLShaderPrecisionFormat" | "WebGLShaderPrecisionFormat?"
| "any" -> ""

| t -> Printf.eprintf "%s: ret %S unknown\n" fname t; "todo"

let type_to_jv fname = function
| "GLenum" -> "of_int"
| "GLboolean" -> "Jv.of_bool"
| "DOMString" -> "of_jstr"
| "sequence<DOMString>" -> "of_jstr_list"
| "sequence<GLenum>" | "sequence<GLuint>" -> "of_list of_int"
| "GLbitfield" | "GLbyte" | "GLshort" | "GLint" | "GLsizei" | "GLintptr"
| "GLsizeiptr" | "GLubyte" | "GLushort" | "GLuint" | "GLint64" | "GLuint64" ->
    "of_int"
| "GLfloat" | "GLclampf" -> "of_float"
| "WebGLBuffer" | "WebGLBuffer?"
| "WebGLFramebuffer" | "WebGLFramebuffer?"
| "WebGLProgram" | "WebGLProgram?"
| "WebGLQuery" | "WebGLQuery?"
| "WebGLRenderbuffer" | "WebGLRenderbuffer?"
| "WebGLSampler" | "WebGLSampler?"
| "WebGLShader" | "WebGLShader?"
| "sequence<WebGLShader>?"
| "WebGLSync" | "WebGLSync?"
| "WebGLTexture" | "WebGLTexture?"
| "WebGLTransformFeedback" | "WebGLTransformFeedback?"
| "WebGLUniformLocation" | "WebGLUniformLocation?"
| "WebGLVertexArrayObject" | "WebGLVertexArrayObject?"
| "WebGLActiveInfo" | "WebGLActiveInfo?"
| "WebGLShaderPrecisionFormat" | "WebGLShaderPrecisionFormat?"
| "any" -> ""
| "Float32List" -> "Tarray.to_jv"
| "Uint32List" -> "Tarray.to_jv"
| "Int32List" -> "Tarray.to_jv"
| "ArrayBufferView" | "ArrayBufferView?" -> "Tarray.to_jv"
| "BufferSource?" | "BufferSource" -> "Tarray.Buffer.to_jv"
| "TexImageSource" -> ""
| t -> Printf.eprintf "%s: inj %S unknown\n" fname t; "todo"

let func_ml func =
  let fname = ocaml_name func.name in
  (* We drop optional arguments *)
  let args = List.filter (fun a -> not a.optional) func.args in
  let ret =
    let ret = type_of_jv func.name func.ret in
    if ret = "" then "" else ret ^ " @@ "
  in
  let args_names = String.concat " " (List.map (fun {n; _} -> n) args) in
  let arg_conv a =
    let conv = type_to_jv func.name a.type' in
    if conv = "" then a.n else conv ^ " " ^ a.n
  in
  let arg_convs = String.concat "; " (List.map arg_conv args) in
  Format.printf "  @[<v>@[let %s c %s =@]@,\
                        @[  %sJv.call c \"%s\" Jv.[|%s|]@]@,@]@."
    fname args_names ret func.name arg_convs

let out_funcs out_fmt funcs =
  let out_func fname funs () = match funs with
  | [f] -> out_fmt f
  | funcs ->
      Printf.printf "(* OVERLOADED\n%!";
      List.iter out_fmt funcs;
      Printf.printf "*)\n%!"
  in
  String.Map.fold out_func funcs ()

let out funcs = function
| `Mli -> out_funcs func_mli funcs
| `Ml -> out_funcs func_ml funcs
| `Dump -> dump funcs

let gen file outfmt =
  let* file = Fpath.of_string file in
  let* data = Os.File.read file in
  let* funcs = parse_funcs ~file data in
  out funcs outfmt;
  Ok 0

let main () =
  let usage = "Usage: gen [--input FILE | --mli | --ml] " in
  let file = ref "glfuns.spec" in
  let outfmt = ref `Dump in
  let args =
    ["--input", Arg.Set_string file, "The file to read";
     "--dump", Arg.Unit (fun () -> outfmt := `Mli), "Dump parse.";
     "--mli", Arg.Unit (fun () -> outfmt := `Mli), "Generate mli.";
     "--ml", Arg.Unit (fun () -> outfmt := `Ml), "Generate ml." ]
  in
  let fail_pos s =
    raise (Arg.Bad (Printf.sprintf "Don't know what to do with %S" s))
  in
  Arg.parse args fail_pos usage;
  exit (Log.if_error ~use:1 @@ gen !file !outfmt)

let () = if !Sys.interactive then () else main ()
