type loc = Cmarkit.Textloc.t

module Error : sig
  type t =
    | DuplicateID of { id : string; previous_occurrence : loc }
    | MissingFile of { file : string; error_msg : string }
    | WrongType of unit
    | ParsingError of { action : string; msg : string }

  val pp : Format.formatter -> t -> unit
end

type t = { error : Error.t; loc : loc }

val to_grace :
  (string -> Grace.Source.t) -> t -> Error.t Grace.Diagnostic.t option

val pp : Format.formatter -> t -> unit
val add : t -> unit
val with_ : (unit -> 'a) -> 'a * t list
val to_code : Error.t -> string
