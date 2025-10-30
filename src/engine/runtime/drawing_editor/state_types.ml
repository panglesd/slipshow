type erased = {
  at : float Lwd.var;
  track : int Lwd.var;
  selected : bool Lwd.var;
  preselected : bool Lwd.var;
}

type stro = {
  id : string;
  scale : float;
  path :
    ((float * float) * float) list Lwd.var (* TODO: (position * time) list *);
  end_at : float Lwd.t;
  starts_at : float Lwd.t;
  color : Drawing.Color.t Lwd.var;
  stroker : Drawing.Types.Tool.stroker;
  width : Drawing.Types.Width.t;
  selected : bool Lwd.var;
  preselected : bool Lwd.var;
  track : int Lwd.var;
  erased : erased option Lwd.var;
}

type t = {
  strokes : stro Lwd_table.t;
  total_time : float Lwd.var;
  record_id : int;
}
(** Ordered by time *)

type editing_tool = Select | Move | Scale
