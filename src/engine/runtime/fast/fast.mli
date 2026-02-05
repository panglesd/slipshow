type hurry_bomb

val has_detonated : hurry_bomb -> bool
val detonate : hurry_bomb -> unit
val wait : hurry_bomb -> unit Fut.t

type mode = private Normal of hurry_bomb | Counting_for_toc | Fast | Slow

val normal : unit -> mode
val counting_for_toc : mode
val slow : mode
val fast : mode
val is_fast : mode -> bool
