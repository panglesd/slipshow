(** {1 Main loop}
    Outputting an interface to a TTY and interacting with it
*)

open Notty_unix
open Nottui

val step : ?process_event:bool -> ?timeout:float -> renderer:Renderer.t ->
  Term.t -> ui Lwd.root -> unit
(** Run one step of the main loop.
    Update output image describe by the provided [root].
    If [process_event], wait up to [timeout] seconds for an input event, then
    consume and dispatch it. *)

val run :
  ?tick_period:float -> ?tick:(unit -> unit) ->
  ?term:Term.t -> ?renderer:Renderer.t ->
  ?quit:bool Lwd.var -> ?quit_on_escape:bool ->
  ?quit_on_ctrl_q:bool -> ui Lwd.t -> unit
(** Repeatedly run steps of the main loop, until either:
    - [quit] becomes true,
    - the ui computation raises an exception,
    - if [quit_on_ctrl_q] was true or not provided, wait for Ctrl-Q event
    - if [quit_on_escape] was true or not provided, wait for Escape event
    Specific [term] or [renderer] instances can be provided, otherwise new
    ones will be allocated and released.
    To simulate concurrency in a polling fashion, tick function and period
    can be provided. Use the [Lwt] backend for real concurrency.
  *)
