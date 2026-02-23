type loc = Cmarkit.Textloc.t

val loc_of_ploc : loc -> Actions_arguments.Parse.loc -> loc

type t =
  | DuplicateID of { id : string; occurrences : loc list }
  | MissingFile of { file : string; error_msg : string; locs : loc list }
  | WrongType of { loc_reason : loc; loc_block : loc; expected_type : string }
  | ParsingError of { action : string; msg : string; loc : loc }
  | ParsingWarnor of { warnor : Actions_arguments.Parse.warnor; loc : loc }
  | MissingID of { id : string; loc : loc }

val pp : Format.formatter -> t -> unit
val to_grace : (string -> Grace.Source.t) -> t -> t Grace.Diagnostic.t option
val add : t -> unit
val with_ : (unit -> 'a) -> 'a * t list
val to_code : t -> string
