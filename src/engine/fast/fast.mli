(** Will be fast if:
    - We start from a specific state as given by a hash ([#15]) or a message
    - We click on the table of content *)

val with_fast : (unit -> 'a Fut.t) -> 'a Fut.t
(** [with_fast f] runs [f], with calls to {!is_fast} returning [true]. [f]
    should not raise *)

val is_fast : unit -> bool
(** [is_fast ()] returns [true] iff it is called inside {!with_fast} *)
