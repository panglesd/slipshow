(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

(* Benchmarker for Cmarkit. Just renders to HTML the way `cmark` does. *)

let ( let* ) = Result.bind

let read_file file =
  try
    let ic = if file = "-" then stdin else open_in_bin file in
    let finally () = if file = "-" then () else close_in_noerr ic in
    Fun.protect ~finally @@ fun () -> Ok (In_channel.input_all ic)
  with
  | Sys_error err -> Error err

let to_html file exts locs layout unsafe =
  let strict = not exts and safe = not unsafe in
  let* content = read_file file in
  let doc = Cmarkit.Doc.of_string ~layout ~locs ~file ~strict content in
  let r = Cmarkit_html.xhtml_renderer ~safe () in
  let html = Cmarkit_renderer.doc_to_string r doc in
  Ok (print_string html)

let main () =
  let strf = Printf.sprintf in
  let usage = "Usage: bench [OPTION]… [FILE.md]" in
  let layout = ref false in
  let locs = ref false in
  let unsafe = ref false in
  let exts = ref false in
  let file = ref None in
  let args =
    [ "--layout", Arg.Set layout, "Keep layout information.";
      "--locs", Arg.Set locs, "Keep locations.";
      "--exts", Arg.Set exts, "Activate supported extensions";
      "--unsafe", Arg.Set unsafe, "Keep HTML blocks and raw HTML"; ]
  in
  let pos s = match !file with
  | Some _ -> raise (Arg.Bad (strf "Don't know what to do with %S" s))
  | None -> file := Some s
  in
  Arg.parse args pos usage;
  let file = Option.value ~default:"-" !file in
  match to_html file !exts !locs !layout !unsafe with
  | Error e -> Printf.eprintf "bench: %s\n%!" e; 1
  | Ok () -> 0

let () = if !Sys.interactive then () else exit (main ())

(*---------------------------------------------------------------------------
   Copyright (c) 2023 The cmarkit programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
