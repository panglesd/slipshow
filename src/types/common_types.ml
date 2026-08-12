open Sexplib.Std
module Special_strings = Special_strings

type gui_id = Id of string | Loc of string [@@deriving sexp]
