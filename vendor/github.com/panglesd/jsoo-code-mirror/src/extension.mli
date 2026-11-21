type t
(** Extensions for the editor *)

include Jv.CONV with type t := t

val of_list : t list -> t
(** [of_list l] is the extensions in [l] as one: CodeMirror's [Extension]
    includes arrays of extensions. *)
