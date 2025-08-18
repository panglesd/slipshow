open Fut.Syntax

let handle_error = function
  | Ok x -> x
  | Error e ->
      Brr.Console.(log [ e ]);
      assert false

let parse_src base64PDF =
  let raw = Brr.Base64.decode base64PDF |> handle_error in
  let raw = Brr.Base64.data_to_binary_jstr raw in
  Brr.Tarray.of_binary_jstr raw |> handle_error

let handle elem src resolution =
  let src = parse_src src in
  let src = Pdfjs_ocaml.Array src in
  let* pdf =
    Pdfjs_ocaml.get_document src
    |> Pdfjs_ocaml.Pdf_document_loading_task.promise
  in
  let pdf = pdf |> handle_error in
  let num_pages = Pdfjs_ocaml.Pdf_document_proxy.num_pages pdf in
  let* l =
    Fut.of_list
    @@ List.init num_pages (fun i ->
           Pdfjs_ocaml.Pdf_document_proxy.get_page pdf (i + 1))
  in
  let l = List.map handle_error l in
  let+ res =
    Fut.of_list
    @@ List.mapi
         (fun i page ->
           let canvas = Brr.El.canvas [] in
           let canvas_el = canvas in
           Brr.El.append_children elem [ canvas ];
           let canvas = Brr_canvas.Canvas.of_el canvas in
           let scale = resolution /. 72. in
           let viewport = Pdfjs_ocaml.Pdf_page_proxy.get_viewport ~scale page in
           let canvas_context = Brr_canvas.C2d.get_context canvas in
           let () =
             let width = Pdfjs_ocaml.Page_viewport.width viewport in
             let height = Pdfjs_ocaml.Page_viewport.height viewport in
             Brr_canvas.Canvas.set_h canvas (height |> int_of_float);
             Brr_canvas.Canvas.set_w canvas (width |> int_of_float)
           in
           let render_task =
             Pdfjs_ocaml.Pdf_page_proxy.render page ~viewport ~canvas_context
           in
           let () =
             Brr.El.set_class
               (Jstr.v "slipshow__carousel_children")
               true canvas_el
           in
           let () =
             if i = 0 then
               Brr.El.set_class
                 (Jstr.v "slipshow__carousel_active")
                 true canvas_el
           in
           Brr.Console.(log [ canvas_el ]);
           Pdfjs_ocaml.Render_task.promise render_task)
         l
  in
  List.iter
    (function
      | Ok () -> ()
      | Error e -> Brr.Console.(error [ "Error while rendering pdf:"; e ]))
    res;
  ()

let activate root =
  Brr.El.fold_find_by_selector ?root
    (fun pdf_elem acc ->
      let* () = acc in
      let src = Brr.El.at (Jstr.v "pdf-src") pdf_elem |> Option.get in
      let resolution =
        Brr.El.at (Jstr.v "pdf-resolution") pdf_elem
        |> Option.map Jstr.to_string
        |> Option.value ~default:"300"
      in
      let resolution =
        match float_of_string_opt resolution with
        | None ->
            Brr.Console.(error [ "Failed to parse pdf-resolution"; resolution ]);
            300.
        | Some x -> x
      in

      handle pdf_elem src resolution)
    (Jstr.v "[slipshow-pdf]") (Fut.return ())

let () =
  let do_ el =
    let root = Jv.to_option Brr.El.of_jv el in
    let fut =
      let open Fut.Syntax in
      let+ res = activate root in
      Ok res
    in
    Fut.to_promise ~ok:(fun () -> Jv.undefined) fut
  in
  Jv.set Jv.global "slipshow__do_pdf" (Jv.callback ~arity:1 do_)
