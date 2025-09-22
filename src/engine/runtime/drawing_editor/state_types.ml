type pfo = {
  size : float option Lwd.var;
  thinning : float option;
  smoothing : float option;
  streamline : float option;
}

type stro = {
  id : string;
  scale : float;
  path : ((float * float) * float) list (* TODO: (position * time) list *);
  total_duration : float;
  color : Drawing.Color.t Lwd.var;
  opacity : float Lwd.var;
  options : pfo;
  selected : bool Lwd.t Lwd.var;
}

type timed_event = { event : stro; time : float Lwd.var }

type t = timed_event list
(** Ordered by time *)

type record = { start_time : float; evs : t }
