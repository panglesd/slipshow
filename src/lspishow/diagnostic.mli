val linoloc_of_textloc : Diagnosis.loc -> Linol_lwt.Range.t

val of_error :
  root:Fpath.t -> file:Fpath.t -> Diagnosis.t -> Linol_lwt.Diagnostic.t list
