(** {{:https://github.com/mozilla/pdf.js/}PDF.js} is a javascript library for
    rendering PDFs in a canvas. This module contains bindings to its API.

    I think that the best way to understand how to use it is to have a look at
    the {{:https://github.com/panglesd/pdfjs_ocaml/tree/main/example}example},
    which is the OCaml version of the PDF.js base64 pdf
    {{:https://mozilla.github.io/pdf.js/examples/}example}. *)

module Page_viewport : sig
  type t

  val width : t -> float
  val height : t -> float

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

module Render_task : sig
  type t

  val promise : t -> unit Fut.t

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

module Pdf_page_proxy : sig
  type t

  val get_viewport :
    scale:float ->
    ?rotation:float ->
    ?offset_x:float ->
    ?offset_y:float ->
    ?dont_flip:bool ->
    t ->
    Page_viewport.t

  val render :
    canvas_context:Brr_canvas.C2d.t ->
    viewport:Page_viewport.t ->
    ?intent:string ->
    t ->
    Render_task.t

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

module Pdf_document_proxy : sig
  type t

  val num_pages : t -> int
  val get_page : t -> int -> Pdf_page_proxy.t Fut.or_error

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

module Pdf_document_loading_task : sig
  type t

  val destroyed : t -> bool

  val doc_id : t -> Jstr.t
  (** TODO *)

  val on_password : t -> ('a -> 'b) -> unit
  (** TODO *)

  val on_progress : t -> ('a -> 'b) -> unit
  (** TODO *)

  val promise : t -> Pdf_document_proxy.t Fut.or_error
  val destroy : t -> unit Fut.or_error

  val get_data : t -> ('a, 'b) Brr.Tarray.t Fut.or_error
  (** TODO *)

  (**/**)

  include Jv.CONV with type t := t

  (**/**)
end

type src =
  | String of Jstr.t
  | Url of Brr.Uri.t
  | Array of Brr.Tarray.uint8
  | ArrayBuffer of Brr.Tarray.Buffer.t

val get_document : src -> Pdf_document_loading_task.t

module GlobalWorkerOptions : sig
  val set_worker_port : Jstr.t -> unit
  val get_worker_port : unit -> Jv.t
  val set_worker_src : Jstr.t -> unit
  val get_worker_src : unit -> Jv.t

  (** PDF.js uses a "web worker" to render the PDF. The script for the webworker
      has to be in another file. This allows to set the URL and port to fetch
      the worker source file.Brr

      However, you'll likely not need this: By default, this library sets the
      worker script url to a blob URL (an URL containing data) containing the
      worker script! *)
end
