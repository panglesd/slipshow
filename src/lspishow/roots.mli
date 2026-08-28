type root = Slipshow_server.root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : Slipshow_server.to_server Lwt_condition.t;
  version : string;
}

type t = (Fpath.t, root) Hashtbl.t

val buffers : t
(** The roots for the opened buffers. *)

val saved : t
(** The roots for the saved buffers. *)

val update_root :
  should_broadcast:bool ->
  Slipshow.Compile.file_reader ->
  t ->
  (Slipshow.Ast.unit' * Diagnosis.t list) Fpath.map ->
  Fpath.t ->
  root
