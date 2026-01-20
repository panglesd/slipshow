open Code_mirror

val lint : Jv.t
(** Global lint value *)

module Action : sig
  type t
  (** The type for actions associated with a diagnostic *)

  val create :
    name:string -> (view:Editor.View.t -> from:int -> to_:int -> unit) -> t
  (** [create ~name f] makes a new action with a function to call when the user activates the action *)
end

module Diagnostic : sig
  type t
  type severity = Info | Warning | Error

  val severity_of_string : string -> severity
  val severity_to_string : severity -> string

  val create :
    ?source:string ->
    ?actions:t array ->
    from:int ->
    to_:int ->
    severity:severity ->
    message:string ->
    unit ->
    t

  val severity : t -> severity
  val from : t -> int
  val to_ : t -> int
  val source : t -> Jstr.t option
  val actions : t -> Action.t array option
  val message : t -> Jstr.t
end

val create :
  ?delay:int ->
  (Editor.View.t -> Diagnostic.t array Fut.t) ->
  Code_mirror.Extension.t
