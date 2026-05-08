val linoloc_of_textloc : Diagnosis.loc -> Linol_lwt.Range.t
val of_error : file:string -> Diagnosis.t -> Linol_lwt.Diagnostic.t list
