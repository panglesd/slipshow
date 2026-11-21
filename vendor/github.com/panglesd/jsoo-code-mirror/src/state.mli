module SelectionRange : sig
  type t

  include Jv.CONV with type t := t

  val from : t -> int
  val to_ : t -> int
  val anchor : t -> int
  val head : t -> int
  val empty : t -> bool
  val assoc : t -> int
end

module EditorSelection : sig
  type t

  include Jv.CONV with type t := t

  val editor_selection : Jv.t lazy_t
  val create : ranges:SelectionRange.t list -> ?main_index:int -> unit -> t

  val cursor :
    pos:int ->
    ?assoc:int ->
    ?bidiLevel:int ->
    ?goalColumn:int ->
    unit ->
    SelectionRange.t

  val range :
    anchor:int ->
    head:int ->
    ?goalColumn:int ->
    ?bidiLevel:int ->
    unit ->
    SelectionRange.t

  val ranges : t -> SelectionRange.t list
  val main : t -> SelectionRange.t
end

module EditorStateConfig : sig
  type t

  include Jv.CONV with type t := t

  val undefined : t

  val create :
    ?doc:string ->
    ?selection:EditorSelection.t ->
    ?extensions:Extension.t ->
    unit ->
    t
end

module ChangeDesc : sig
  type t

  include Jv.CONV with type t := t

  val mapPos : t -> int -> int
end

module Range : sig
  type 'a t

  include Tjv.CONV with type 'a t := 'a t

  val value : 'a t -> 'a
end

module RangeSet : sig
  type 'a t

  include Tjv.CONV with type 'a t := 'a t

  val map : 'a t -> ChangeDesc.t -> 'a t
  val update : ?add:'a Range.t list -> ?sort:bool -> 'a t -> 'a t
  val of_ : ?sort:bool -> 'a Range.t list -> 'a t option
end

module Text : sig
  type t

  include Jv.CONV with type t := t

  val length : t -> int
  val line : int -> t -> Jv.t
  val line_at : int -> t -> Jv.t
  val to_string : t -> string
  val to_jstr_array : t -> Jstr.t array
end

module Line : sig
  type t = Jv.t

  val from : Jv.t -> int
  val to_ : Jv.t -> int
  val number : Jv.t -> int
  val text : Jv.t -> Jstr.t
  val length : Jv.t -> int
end

module StateEffect : sig
  type 'a t

  include Tjv.CONV with type 'a t := 'a t

  val state_effect : Jv.t lazy_t
  val define : ('a -> Jv.t) -> (Jv.t -> 'a) -> 'a t

  val define_ :
    ('a -> Jv.t) ->
    (Jv.t -> 'a) ->
    map:('a -> ChangeDesc.t -> 'a option) ->
    'a t

  val is : Jv.t t -> 'a t -> bool
  val value : Jv.t t -> 'a t -> 'a option
  val of_ : 'a t -> 'a -> 'a t
  val append_config : unit -> Extension.t t
end

module Compartment : sig
  type t

  include Jv.CONV with type t := t

  val make : unit -> t
  val of_ : t -> Extension.t -> Extension.t
  val reconfigure : t -> Extension.t -> Extension.t StateEffect.t
end

module ChangeSet : sig
  type t

  include Jv.CONV with type t := t

  val g : Jv.t lazy_t
  val to_json : t -> Jv.t
  val of_json : Jv.t -> t
end

module ChangeSpec : sig
  type t

  include Jv.CONV with type t := t

  val create : from:int -> ?to_:int -> ?insert:string -> unit -> t
  val of_change_set : ChangeSet.t -> t
  val of_list : t list -> t
end

module TransactionSpec : sig
  type t = Jv.t

  include Jv.CONV with type t := t

  type selection =
    | Short of { anchor : int; head : int option }
    | Selection of EditorSelection.t

  val selection_to_jv : selection -> Jv.t

  val create :
    ?effects:'a StateEffect.t list ->
    ?selection:selection ->
    ?changes:ChangeSpec.t ->
    ?scroll_into_view:bool ->
    unit ->
    t
end

type 'a state_field
type transaction

module EditorState : sig
  type t

  include Jv.CONV with type t := t

  val editor_state : Jv.t lazy_t
  val create : ?config:EditorStateConfig.t -> unit -> t
  val doc : t -> Text.t
  val field : t -> 'a state_field -> 'a
  val selection : t -> EditorSelection.t
  val update : t -> Jv.t list -> transaction
end

module Transaction : sig
  type t = transaction

  include Jv.CONV with type t := t

  val effects : t -> Jv.t StateEffect.t list
  val changes : t -> ChangeDesc.t
  val state : t -> EditorState.t
  val doc_changed : t -> bool
end

module StateField : sig
  type 'a t = 'a state_field

  include Tjv.CONV with type 'a t := 'a t

  val extension : 'a t -> Extension.t
  val state_field : Jv.t lazy_t

  val define :
    ?compare:('a -> 'a -> bool) ->
    ?provide:('a t -> Extension.t) ->
    ('a -> Jv.t) ->
    (Jv.t -> 'a) ->
    create:(EditorState.t -> 'a) ->
    update:('a -> Transaction.t -> 'a) ->
    'a t

  val init : 'a t -> (EditorState.t -> 'a) -> Extension.t
end

module Facet : sig
  type ('input, 'output) t

  val to_jv : ('input, 'output) t -> Jv.t
  val to_conv : ('input, 'output) t -> 'input Tjv.conv
  val create : 'input Tjv.conv -> Jv.t -> ('input, 'output) t
  val of_ : ('i, 'o) t -> 'i -> Extension.t
  val from : ('i, 'o) t -> 'a StateField.t -> Extension.t
  val from' : ('i, 'o) t -> 'a StateField.t -> ('a -> 'i) -> Extension.t
end
