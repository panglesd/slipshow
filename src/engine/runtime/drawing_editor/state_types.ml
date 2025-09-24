type pfo = {
  size : float Lwd.var;
  thinning : float option;
  smoothing : float option;
  streamline : float option;
}

type stro = {
  id : string;
  scale : float;
  path : ((float * float) * float) list (* TODO: (position * time) list *);
  end_at : float;
  color : Drawing.Color.t Lwd.var;
  opacity : float Lwd.var;
  options : pfo;
}

type t = stro list
(** Ordered by time *)
