type to_server =
  | Update
  | Control of Proto.Server_to_client.control
  | ActivateGUI of Common_types.gui_id
  | DeActivateGUI

type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : to_server Lwt_condition.t;
  version : string;
}

type roots = (Fpath.t -> root option) * (unit -> Fpath.t list)

val do_serve :
  port:int ->
  Fpath.t ->
  (unit ->
  ( (Slipshow.Ast.units * Diagnosis.t list) * Fpath.set,
    [ `Msg of string ] )
  result) ->
  unit

val do_watch :
  Fpath.t -> (unit -> (Fpath.Set.t, [ `Msg of string ]) result) -> unit

module Server : sig
  val do_serve :
    port:int ->
    to_lsp_server:
      (Proto.Client_to_server.t -> root -> unit)
      option ->
    roots ->
    (unit, [> `Addr_in_use ]) result Lwt.t
end
