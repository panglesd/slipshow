(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Future values.

    A future ['a Fut.t] is an undetermined value of type ['a] that
    becomes determined at an arbitrary point in the future. The future
    acts as a placeholder for the value while it is undetermined.

    Future values do not support exceptions, you need to turn them
    into a value and make them appear in the future's type, for
    example using {!Fut.error}.

    [Brr] uses future values [('a, 'b) result Fut.t] to type the
    resolution and rejection case of JavaScript promises. Since most
    rejection cases given by browser APIs are simply {!Jv.Error.t}
    values, the dedicated {!Fut.or_error} type alias can be used for
    that.

    {!Fut.t} values are {e indirectly} implemented as
    {{:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise}Promise}
    objects that never reject. You can't substitute them directly for
    JavaScript promises and vice-versa, use {!of_promise} and
    {!to_promise} to convert between them. *)

(** {1:futs Futures} *)

type 'a t
(** The type for futures with value of type ['a]. *)

val create : unit -> 'a t * ('a -> unit)
(** [create ()] is [(f, set] with [f] the future value and [set] the
    function to [set] it. The latter can be called only once, a
    {!Jv.exception-Error} is thrown otherwise. *)

val await : 'a t -> ('a -> unit) -> unit
(** [await f k] waits for [f] to determine [v] and continues with [k
    v]. If the future never determines [k] is not invoked. [k] must
    not raise. *)

val return : 'a -> 'a t
(** [return v] is a future that determines [v]. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map fn f] is [return (fn v)] with [v] the value determined by [f].
    [fn] must not raise. *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
(** [bind f fn] is the future [fn v] with [v] the value determined by [f].
    [fn] must not raise. *)

val pair : 'a t -> 'b t -> ('a * 'b) t
(** [pair f0 f1] is the future that determines with the value of [f0]
    and [f1]. *)

val of_list : 'a t list -> 'a list t
(** [of_list fs] determines with the values of all future [fs] in the
    same order. *)

val tick : ms:int -> unit t
(** [tick ~ms] determines [()] [ms] milliseconds after creation using
    {{:https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setTimeout}[setTimeout]}. *)

(** {1:fut Future results} *)

type nonrec ('a, 'b) result = ('a, 'b) result t
(** The type for future values that may error. *)

type 'a or_error = ('a, Jv.Error.t) result
(** The type for future values that error with a JavaScript error. *)

val ok : 'a -> ('a, 'b) result
(** [ok v] is [return (Ok v)]. *)

val error : 'b -> ('a, 'b) result
(** [error e] is [return (Error e)]. *)

(** {1:promises Converting with JavaScript promises} *)

val of_promise : ok:(Jv.t -> 'a) -> Jv.Promise.t -> 'a or_error
(** [of_promise ~ok p] is [of_promise' ~ok ~error:Jv.to_error. p]. *)

val to_promise : ok:('a -> Jv.t) -> 'a or_error -> Jv.Promise.t
(** [to_promise p] is [to_promise' ~ok ~error:Jv.of_error p]. *)

val of_promise' :
  ok:(Jv.t -> 'a) -> error:(Jv.t -> 'b) -> Jv.Promise.t -> ('a, 'b) result
(** [of_promise ~ok ~error p] is a future for the promise [p]. The
    future determines with [Ok (ok v)] if [p] resolves with [v] and
    with [Error (error e)] if [p] rejects with [e]. *)

val to_promise' :
  ok:('a -> Jv.t) -> error:('b -> Jv.t) -> ('a, 'b) result -> Jv.Promise.t
(** [to_promise f] is a JavaScript promise for the future [f] that
    resolves the promise with [ok v] if the future determines with [Ok
    v] and rejects with [e] if the future determines with [Error
    e]. *)

(** {1:syntax Future syntaxes} *)

(** Future syntax. *)
module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  (** [let*] is {!bind}. *)

  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
  (** [and*] is {!pair}. *)

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  (** [let+] is {!map}. *)

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
  (** [and+] is {!pair}. *)
end

(** Future result syntax.

    Always returns the first (syntactically speaking) error. *)
module Result_syntax : sig
  val ( let* ) : ('a, 'e) result -> ('a -> ('b, 'e) result) -> ('b, 'e) result
  val ( and* ) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
  val ( let+ ) : ('a, 'e) result -> ('a -> 'b) -> ('b, 'e) result
  val ( and+ ) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
end
