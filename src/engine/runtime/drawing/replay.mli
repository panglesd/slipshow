val replay : ?speedup:float -> Record.t -> unit Fut.t
val draw_until : elapsed_time:float -> Record.t -> Brr.El.t list
