type root = {
  units : Slipshow.Ast.units;
  diagnostics : Diagnosis.t list;
  condition : unit Lwt_condition.t;
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
  val do_serve : port:int -> roots -> unit Lwt.t
end
