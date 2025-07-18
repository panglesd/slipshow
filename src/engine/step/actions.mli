module type S = sig
  type args

  val on : string
  val action_name : string
  val parse_args : Brr.El.t -> string -> (args, [> `Msg of string ]) result
  val do_ : Universe.Window.t -> args -> unit Undoable.t
end

module Pause : sig
  type args = Brr.El.t list

  include S with type args := args

  val setup : Brr.El.t list -> unit Undoable.t
end

module type Move = sig
  type args = {
    margin : float option;
    duration : float option;
    elem : Brr.El.t;
  }

  include S with type args := args
end

module type SetClass = S with type args = Brr.El.t list

module Up : Move
module Down : Move
module Center : Move
module Scroll : Move
module Enter : Move
module Unstatic : SetClass
module Static : SetClass
module Reveal : SetClass
module Unreveal : SetClass
module Emph : SetClass
module Unemph : SetClass
module Step : S with type args = unit

val exit : Universe.Window.t -> Brr.El.t -> unit Undoable.t

module Focus : sig
  type args = {
    margin : float option;
    duration : float option;
    elems : Brr.El.t list;
  }

  include S with type args := args
end

module Unfocus : S with type args = unit
module Execute : S with type args = Brr.El.t list

val all : (module S) list
