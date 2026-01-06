val actualize : Global_state.t -> unit -> unit

val go_next : Global_state.t -> Universe.Window.t -> unit Fut.t Fut.t
(** We return a [_ Fut.t Fut.t] here to allow to wait for [with_step_transition]
    to update the state, without waiting for the actual transition to be
    finished. *)

val go_prev : Global_state.t -> Universe.Window.t -> unit Fut.t
val goto : Global_state.t -> int -> Universe.Window.t -> unit Fut.t

module Excursion : sig
  val start : unit -> unit
  (** Start an "excursion". The excursion is stopped when the step is set (via
      {!goto}, {!go_next} or {!go_prev}). When an excursion is stopped, the
      window returns where it was when the excursion started.

      Calling [start] when an excursion already started does nothing. *)
end
