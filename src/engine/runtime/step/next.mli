val actualize : unit -> unit
val go_next : Universe.Window.t -> unit Fut.t
val go_prev : Universe.Window.t -> unit Fut.t
val goto : int -> Universe.Window.t -> unit Fut.t

module Excursion : sig
  val start : unit -> unit
  (** Start an "excursion". The excursion is stopped when the step is set (via
      {!goto}, {!go_next} or {!go_prev}). When an excursion is stopped, the
      window returns where it was when the excursion started.

      Calling [start] when an excursion already started does nothing. *)
end
