open Code_mirror

val lint : Jv.t
(** Global lint value *)

module Action : sig
  type t
  (** The type for actions associated with a diagnostic *)

  val create :
    name:string -> (view:View.EditorView.t -> from:int -> to_:int -> unit) -> t
  (** [create ~name f] makes a new action with a function to call when the user
      activates the action *)
end

module Diagnostic : sig
  type t
  type severity = Hint | Info | Warning | Error

  val severity_of_string : string -> severity
  val severity_to_string : severity -> string

  val create :
    ?source:string ->
    ?actions:Action.t list ->
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
  val actions : t -> Action.t list option
  val message : t -> Jstr.t
end

val create :
  ?delay:int ->
  (View.EditorView.t -> Diagnostic.t list Fut.t) ->
  Code_mirror.Extension.t
