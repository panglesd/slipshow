open Sexplib.Std

type gui_id = Id of string | Loc of string [@@deriving sexp]
