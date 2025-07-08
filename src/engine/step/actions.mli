module Pause : sig
  val setup : Brr.El.t -> unit Undoable.t
  val do_ : Brr.El.t -> unit Undoable.t
end

val up : Universe.Window.t -> Brr.El.t -> unit Undoable.t
val down : Universe.Window.t -> Brr.El.t -> unit Undoable.t
val center : Universe.Window.t -> Brr.El.t -> unit Undoable.t
val enter : Universe.Window.t -> Brr.El.t -> unit Undoable.t
val exit : Universe.Window.t -> Brr.El.t -> unit Undoable.t
val unstatic : Brr.El.t list -> unit Undoable.t
val static : Brr.El.t list -> unit Undoable.t

module Focus : sig
  type args = {
    margin : float option;
    delay : float option;
    elems : Brr.El.t list;
  }

  val parse_args : Brr.El.t -> string -> (args, [> `Msg of string ]) result
  val do_ : Universe.Window.t -> args -> unit Undoable.t
end

val unfocus : Universe.Window.t -> unit -> unit Undoable.t
val reveal : Brr.El.t list -> unit Undoable.t
val unreveal : Brr.El.t list -> unit Undoable.t
val emph : Brr.El.t list -> unit Undoable.t
val unemph : Brr.El.t list -> unit Undoable.t
val scroll : Universe.Window.t -> Brr.El.t -> unit Undoable.t
