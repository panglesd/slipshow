(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Fut.Result_syntax
open Brr

let eval_err_to_error err = (* Do something better ? *)
  Jv.Error.v (Jv.to_jstr @@ Jv.call err "toString" [||])

let eval_of_devtool_eval eval = fun expr ->
  let res, set_res = Fut.create () in
  let cb r err =
    (* Note this doesn't really return json since it can return undefined. *)
    if Jv.is_undefined r && not (Jv.is_undefined err)
    then set_res (Error (eval_err_to_error err))
    else set_res (Ok r)
  in
  match ignore @@ Jv.apply eval Jv.[|of_jstr expr; null; repr cb |] with
  | exception Jv.Error e -> set_res (Error e); res
  | () -> res

let get_eval () : (Jstr.t -> Brr.Json.t Fut.or_error, Jv.Error.t) result =
  let eval_id = ["chrome"; "devtools"; "inspectedWindow"; "eval"] in
  match Jv.find_path Jv.global eval_id with
  | Some eval -> Ok (eval_of_devtool_eval eval)
  | None ->
      let eval_id = String.concat "." eval_id in
      let msg = Jstr.(v "Function " + v eval_id + v " undefined") in
      Error (Jv.Error.v msg)

let try_await_inspected_document_complete eval =
  (* Tests every 100ms for 2s if the inspected document is complete *)
  let is_complete () =
    let complete = Jstr.v "globalThis.document.readyState == \"complete\"" in
    Fut.map (Result.map Jv.to_bool) (eval complete)
  in
  let rec loop = function
  | 0 -> Fut.ok ()
  | n ->
      let* complete = is_complete () in
      if complete then Fut.ok () else
      Fut.bind (Fut.tick ~ms:100) @@ fun () -> loop (n - 1)
  in
  loop 20

let reset_panel () =
  let reload = El.button El.[txt' "Reset panel"] in
  let reload_act _ = Window.reload G.window in
  ignore (Ev.listen Ev.click reload_act (El.as_target reload));
  reload

let rec warn_no_poke panel ui =
  let msg =
    "No OCaml poke found in inspected page.\n\
     Consult the OCaml console manual in ‘odig doc brr’ for more information."
  in
  let retry = El.button El.[txt' "Retry"] in
  let retry_connect _ = ignore (connect_poke panel) in
  ignore (Ev.listen Ev.click retry_connect (El.as_target retry));
  Brr_ocaml_poke_ui.output ui ~kind:`Warning [El.pre [El.txt (Jstr.v msg)]];
  Brr_ocaml_poke_ui.output ui ~kind:`Info [retry];
  ()

and connect_poke panel =
  let store = Brr_ocaml_poke_ui.Store.webext () in
  let* repl = Brr_ocaml_poke_ui.create ~store panel in
  let show_err e =
    Brr_ocaml_poke_ui.output ~kind:`Error repl [El.txt (Jv.Error.message e)]
  in
  match get_eval () with
  | Error e -> show_err e; Fut.ok ()
  | Ok eval ->
      (* It seems difficult to get an event that indicates us
         when the inspected page is ready so we try to probe
         globalThis.document.readyState for completeness *)
      let* () = try_await_inspected_document_complete eval in
      Fut.bind (Brr_ocaml_poke.find_eval'd ~eval) @@ function
      | Error e -> show_err e; Fut.ok ()
      | Ok None -> warn_no_poke panel repl; Fut.ok ()
      | Ok (Some poke) ->
          let buttons = None (* Some [reset_panel ()] *) in
          let drop_target = Document.as_target G.document in
          Brr_ocaml_poke_ui.run ~drop_target ?buttons repl poke; Fut.ok ()

let listen ev func = match Jv.find_path Jv.global ev with
| None -> ()
| Some o ->
    ignore (Jv.call o "addListener" [|Jv.callback ~arity:1 func|])

let setup_reconnect_on_reload panel =
  let prefix = ["chrome"; "devtools"; "network"; ] in
  let on_navigated = prefix @ [ "onNavigated" ] in
  let reconnect _ = ignore (connect_poke panel) in
  listen on_navigated reconnect;
  ()

let setup_theme () =
  let prefix = ["chrome"; "devtools"; "panels"; ] in
  let theme_name = prefix @ ["themeName"] in
  let on_theme_changed = prefix @ ["onThemeChanged"] in
  let set_theme theme =
    let html = Document.root G.document in
    let theme = match theme with `Dark -> "dark" | `Light -> "light" in
    El.set_at (Jstr.v "theme") (Some (Jstr.v theme)) html
  in
  let find_theme () =
    let name = Jv.find_path Jv.global theme_name in
    match Option.map (fun n -> Jstr.to_string (Jv.to_jstr n)) name with
    | Some "dark" -> `Dark
    | None when Window.prefers_dark_color_scheme G.window -> `Dark
    | _ -> `Light
  in
  let change_theme _ = find_theme () in
  set_theme (find_theme ());
  listen on_theme_changed change_theme;
  ()

let main () =
  let panel = El.div [] in
  setup_theme ();
  setup_reconnect_on_reload panel;
  El.set_children (Document.body G.document) [panel];
  connect_poke panel

let () = ignore (main ())
