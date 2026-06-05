module Io : sig
  val read : Fpath.t -> (string, [ `Msg of string ]) result
end

val with_ : Fpath.t -> string -> Slipshow.file_reader
(** [with_ file source] is a file reader that would say that [file] has content
    [source]. *)

val fs : Fpath.t -> Slipshow.file_reader
(** Read from the filesystem *)

val combine :
  Slipshow.file_reader -> Slipshow.file_reader -> Slipshow.file_reader
(** Try first the first file_reader, if it did not work, try the next one **)

module Syntax : sig
  val ( ||| ) :
    Slipshow.file_reader -> Slipshow.file_reader -> Slipshow.file_reader
  (** Same as {!combine}. **)
end
