module type S = sig
  include Actions_arguments.S

  val setup : (Brr.El.t -> args -> unit Fut.t) option
  val setup_all : (unit -> unit Fut.t) option

  type js_args

  val do_js : mode:Fast.mode -> Universe.Window.t -> js_args -> unit Undoable.t

  val do_ :
    mode:Fast.mode -> Universe.Window.t -> Brr.El.t -> args -> unit Undoable.t
end

module Pause :
  S
    with type args := Actions_arguments.ids_or_self
     and type js_args = Brr.El.t list

module type Move = sig
  type args = {
    margin : float option;
    duration : float option;
    target : [ `Self | `Id of string Actions_arguments.W.node ];
  }

  type js_args = {
    elem : Brr.El.t;
    duration : float option;
    margin : float option;
  }

  include S with type args := args and type js_args := js_args
end

module type SetClass =
  S
    with type args = [ `Self | `Ids of string Actions_arguments.W.node list ]
     and type js_args = Brr.El.t list

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

val exit : mode:Fast.mode -> Universe.Window.t -> Brr.El.t -> unit Undoable.t

module Focus : sig
  include module type of Actions_arguments.Focus

  type js_args = {
    margin : float option;
    duration : float option;
    elems : Brr.El.t list;
  }

  include S with type args := args and type js_args := js_args
end

module Unfocus : S with type args = unit
module Execute : S with type args = Actions_arguments.Execute.args

module Play_media :
  S
    with type args = Actions_arguments.Play_media.args
     and type js_args = Brr.El.t list

module Change_page : sig
  include module type of Actions_arguments.Change_page

  type js_args = { elem : Brr.El.t; change : change }

  include S with type args := args and type js_args := js_args
end

val all : (module S) list
