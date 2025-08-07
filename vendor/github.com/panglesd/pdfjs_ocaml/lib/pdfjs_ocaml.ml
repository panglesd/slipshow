let pdfjs_lib = Jv.get Jv.global "pdfjsLib"

module GlobalWorkerOptions = struct
  let global_worker_option = Jv.get pdfjs_lib "GlobalWorkerOptions"

  let set_worker_port s =
    let s = Jv.of_jstr s in
    Jv.set global_worker_option "workerPort" s

  let get_worker_port () = Jv.get global_worker_option "workerPort"

  let set_worker_src s =
    let s = Jv.of_jstr s in
    Jv.set global_worker_option "workerSrc" s

  let get_worker_src () = Jv.get global_worker_option "workerSrc"

  let set_standalone_worker () =
    let blobUrl = Jv.get Jv.global "workerBlobUrl" in
    Jv.set global_worker_option "workerSrc" blobUrl

  let () = set_standalone_worker ()
end

type src =
  | String of Jstr.t
  | Url of Brr.Uri.t
  | Array of Brr.Tarray.uint8
  | ArrayBuffer of Brr.Tarray.Buffer.t

module Get_viewport_parameters = struct
  let make ~scale ~rotation ~offset_x ~offset_y ~dont_flip =
    Jv.obj
      [|
        ("scale", Jv.of_float scale);
        ("rotation", Jv.of_option ~none:Jv.null Jv.of_float rotation);
        ("offsetX", Jv.of_option ~none:Jv.null Jv.of_float offset_x);
        ("offsetY", Jv.of_option ~none:Jv.null Jv.of_float offset_y);
        ("dontFlip", Jv.of_option ~none:Jv.null Jv.of_bool dont_flip);
      |]
end

module Page_viewport = struct
  type t = Jv.t

  let width v = Jv.get v "width" |> Jv.to_float
  let height v = Jv.get v "height" |> Jv.to_float

  include (Jv.Id : Jv.CONV with type t := t)
end

module Render_parameters = struct
  (* type t = { *)
  (*   canvas_context : Brr_canvas.C2d.t; *)
  (*       (\** A 2D context of a DOM Canvas object. *\) *)
  (*   viewport : Page_viewport.t; *)
  (*       (\** Rendering viewport obtained by calling the *)
  (*           {!PDFPageProxy.getViewport} method. *\) *)
  (*   intent : string option; *)
  (*       (\** Rendering intent, can be 'display', 'print', or 'any'. The default *)
  (*           value is 'display'. *\) *)
  (*       (\* annotationMode : int option; *\) *)
  (*       (\*     (\\** Controls which annotations are rendered onto the canvas, for *\) *)
  (*       (\*         annotations with appearance-data; the values from AnnotationMode *\) *)
  (*       (\*         should be used. The following values are supported: - *\) *)
  (*       (\*         `AnnotationMode.DISABLE`, which disables all annotations. - *\) *)
  (*       (\*         `AnnotationMode.ENABLE`, which includes all possible annotations *\) *)
  (*       (\*         (thus it also depends on the `intent`-option, see above). - *\) *)
  (*       (\*         `AnnotationMode.ENABLE_FORMS`, which excludes annotations that *\) *)
  (*       (\*         contain interactive form elements (those will be rendered in the *\) *)
  (*       (\*         display layer). - `AnnotationMode.ENABLE_STORAGE`, which includes *\) *)
  (*       (\*         all possible annotations (as above) but where interactive form *\) *)
  (*       (\*         elements are updated with data from the AnnotationStorage-instance; *\) *)
  (*       (\*         useful e.g. for printing. The default value is *\) *)
  (*       (\*         `AnnotationMode.ENABLE`. *\\) *\) *)
  (*       (\* transform : todo option (\\* Array:.<any:> 	<optional> *\\); *\) *)
  (*       (\*     (\\** Additional transform, applied just before viewport transform. *\\) *\) *)
  (*       (\* background : todo option; *\) *)
  (*       (\*     (\\** Background to use for the canvas. Any valid `canvas.fillStyle` can *\) *)
  (*       (\*         be used: a `DOMString` parsed as CSS value, a `CanvasGradient` *\) *)
  (*       (\*         object (a linear or radial gradient) or a `CanvasPattern` object (a *\) *)
  (*       (\*         repetitive image). The default value is 'rgb(255,255,255)'. NOTE: *\) *)
  (*       (\*         This option may be partially, or completely, ignored when the *\) *)
  (*       (\*         `pageColors`-option is used. *\\) *\) *)
  (*       (\*     (\\* CanvasGradient | CanvasPattern | string 	<optional> *\\) *\) *)

  (*       (\*     (\\* pageColors 	Object 	<optional> *\) *)
  (*       (\*     Overwrites background and foreground colors with user defined ones in order to improve readability in high contrast mode.*\\) *\) *)

  (*       (\*     (\\*optionalContentConfigPromise 	Promise:.<OptionalContentConfig:> 	<optional> *\) *)
  (*       (\*     A promise that should resolve with an OptionalContentConfig created from `PDFDocumentProxy.getOptionalContentConfig`. If `null`, the configuration will be fetched automatically with the default visibility states set. *\\) *\) *)
  (*       (\*     (\\*annotationCanvasMap 	Map:.<string:, HTMLCanvasElement:> 	<optional> *\) *)
  (*       (\*     Map some annotation ids with canvases used to render them.*\\) *\) *)
  (*       (\*     (\\*printAnnotationStorage 	PrintAnnotationStorage 	<optional>*\\) *\) *)

  (*       (\*     (\\*isEditing 	boolean 	<optional> *\) *)
  (*       (\*     Render the page in editing mode.*\\) *\) *)
  (* } *)

  let make ~intent ~viewport ~canvas_context =
    Jv.obj
      [|
        ("canvasContext", Brr_canvas.C2d.to_jv canvas_context);
        ("viewport", Page_viewport.to_jv viewport);
        ("intent", Jv.of_option ~none:Jv.null Jv.of_string intent);
      |]
end

module Render_task = struct
  type t = Jv.t

  let promise v =
    let promise = Jv.get v "promise" in
    Fut.of_promise ~ok:(fun _ -> ()) promise

  include (Jv.Id : Jv.CONV with type t := t)
end

module Pdf_page_proxy = struct
  type t = Jv.t

  let get_viewport ~scale ?rotation ?offset_x ?offset_y ?dont_flip p =
    let params =
      Get_viewport_parameters.make ~scale ~rotation ~offset_x ~offset_y
        ~dont_flip
    in
    Jv.call p "getViewport" [| params |] |> Page_viewport.of_jv

  let render ~canvas_context ~viewport ?intent p =
    let params = Render_parameters.make ~canvas_context ~viewport ~intent in
    Jv.call p "render" [| params |] |> Render_task.of_jv

  include (Jv.Id : Jv.CONV with type t := t)
end

module Pdf_document_proxy = struct
  type t = Jv.t

  let num_pages v = Jv.get v "numPages" |> Jv.to_int

  (* let cache_page_number v ref_ = *)
  (*   Jv.call v "cachePageNumber" ref_ |> Jv.to_option Jv.to_int *)

  let get_page v page_n =
    let page_n = Jv.of_int page_n in
    Jv.call v "getPage" [| page_n |] |> Fut.of_promise ~ok:Pdf_page_proxy.of_jv

  include (Jv.Id : Jv.CONV with type t := t)
end

module Pdf_document_loading_task = struct
  type t = Jv.t

  let destroyed v = Jv.get v "destroyed" |> Jv.to_bool
  let doc_id v = Jv.get v "docId" |> Jv.to_jstr

  let on_password v f =
    let f = Jv.callback ~arity:2 f in
    Jv.set v "onPassword" f

  let on_progress v f =
    let f = Jv.callback ~arity:1 f in
    Jv.set v "onProgress" f

  let promise v = Jv.get v "promise" |> Fut.of_promise ~ok:Fun.id
  let destroy v = Jv.call v "destroy" [||] |> Fut.of_promise ~ok:ignore

  let get_data v =
    Jv.call v "getData" [||] |> Fut.of_promise ~ok:Brr.Tarray.of_jv

  include (Jv.Id : Jv.CONV with type t := t)
end

let get_document (src : src) =
  let src =
    match src with
    | String s -> Jv.of_jstr s
    | Url u -> Brr.Uri.to_jv u
    | Array a -> Brr.Tarray.to_jv a
    | ArrayBuffer a -> Brr.Tarray.Buffer.to_jv a
  in
  Jv.call pdfjs_lib "getDocument" [| src |] |> Pdf_document_loading_task.of_jv
