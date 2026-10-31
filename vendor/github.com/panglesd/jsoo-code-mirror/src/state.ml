include Types.State

module EditorStateConfig = struct
  include EditorStateConfig

  let create :
      ?doc:string ->
      ?selection:EditorSelection.t ->
      ?extensions:Extension.t ->
      unit ->
      t =
   fun ?doc ?selection ?extensions () ->
    let o = Jv.obj [||] in
    Jv.Jstr.set_if_some o "doc" (Option.map Jstr.of_string doc);
    Jv.set_if_some o "selection" (Option.map EditorSelection.to_jv selection);
    Jv.set_if_some o "extensions" (Option.map Extension.to_jv extensions);
    of_jv o
end

module ChangeDesc : sig
  type t

  include Jv.CONV with type t := t

  val mapPos : t -> int -> int
end = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let mapPos : t -> int -> int =
   fun t pos -> Jv.call (to_jv t) "mapPos" [| Jv.of_int pos |] |> Jv.to_int
end

module SelectionRange : sig
  type t

  include Jv.CONV with type t := t

  val from : t -> int
  val to_ : t -> int
  val anchor : t -> int
  val head : t -> int
  val empty : t -> bool
  val assoc : t -> int
end = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let from : t -> int = fun t -> Jv.Int.get t "from"
  let to_ : t -> int = fun t -> Jv.Int.get t "to"
  let anchor : t -> int = fun t -> Jv.Int.get t "anchor"
  let head : t -> int = fun t -> Jv.Int.get t "head"
  let empty : t -> bool = fun t -> Jv.Bool.get t "empty"
  let assoc : t -> int = fun t -> Jv.Int.get t "assoc"
end

module EditorSelection = struct
  include EditorSelection

  let editor_selection = lazy (Jv.get Jv.global "__CM__EditorSelection")

  let create : ranges:SelectionRange.t list -> ?main_index:int -> unit -> t =
   fun ~ranges ?(main_index = 0) () ->
    Jv.call
      (Lazy.force editor_selection)
      "create"
      (Array.of_list
         (List.map SelectionRange.to_jv ranges @ [ Jv.of_int main_index ]))
    |> of_jv

  let cursor :
      pos:int ->
      ?assoc:int ->
      ?bidiLevel:int ->
      ?goalColumn:int ->
      unit ->
      SelectionRange.t =
   fun ~pos ?(assoc = 0) ?bidiLevel ?goalColumn () ->
    let opt x = match x with Some x -> Jv.of_int x | None -> Jv.undefined in
    Jv.call
      (Lazy.force editor_selection)
      "cursor"
      [| Jv.of_int pos; Jv.of_int assoc; opt bidiLevel; opt goalColumn |]
    |> SelectionRange.of_jv

  let range :
      anchor:int ->
      head:int ->
      ?goalColumn:int ->
      ?bidiLevel:int ->
      unit ->
      SelectionRange.t =
   fun ~anchor ~head ?goalColumn ?bidiLevel () ->
    let opt x = match x with Some x -> Jv.of_int x | None -> Jv.undefined in
    Jv.call
      (Lazy.force editor_selection)
      "range"
      [| Jv.of_int anchor; Jv.of_int head; opt goalColumn; opt bidiLevel |]
    |> SelectionRange.of_jv

  let ranges (v : t) =
    Jv.get (to_jv v) "ranges" |> Jv.to_list SelectionRange.of_jv
end

module Range : sig
  type 'a t

  include Tjv.CONV with type 'a t := 'a t

  val value : 'a t -> 'a
end = struct
  type 'a t = 'a Tjv.t

  include (Tjv.Id : Tjv.CONV with type 'a t := 'a t)

  let value (v : 'a t) = Jv.get (to_jv v) "value" |> (conv v).of_jv
end

module RangeSet : sig
  type 'a t

  include Tjv.CONV with type 'a t := 'a t

  val map : 'a t -> ChangeDesc.t -> 'a t
  val update : ?add:'a Range.t list -> ?sort:bool -> 'a t -> 'a t
  val of_ : 'a Range.t list -> 'a t option
end = struct
  type 'a t = 'a Tjv.t

  include (Tjv.Id : Tjv.CONV with type 'a t := 'a t)

  let rangeset = lazy (Jv.get Jv.global "__CM__RangeSet")

  let map : 'a t -> ChangeDesc.t -> 'a t =
   fun v changes ->
    Tjv.map_jv v (fun jv -> Jv.call jv "map" [| ChangeDesc.to_jv changes |])

  let update ?(add = []) ?sort v : 'a t =
    let o = Jv.obj [||] in
    (match add with
    | [] -> ()
    | _ -> Jv.set o "add" (Jv.of_list Range.to_jv add));
    Jv.set_if_some o "sort" (Option.map Jv.of_bool sort);
    let v' = Jv.call (to_jv v) "update" [| o |] in
    of_jv (conv v) v'

  let of_ : 'a Range.t list -> 'a t option =
   fun vs ->
    match vs with
    | [] -> None
    | x :: _ ->
        let conv = Range.conv x in
        let v =
          Jv.call (Lazy.force rangeset) "of" [| Jv.of_list Range.to_jv vs |]
        in
        Some (of_jv conv v)
end

module Text = struct
  include Text

  let length (t : t) = Jv.Int.get (to_jv t) "length"
  let line n (t : t) = Jv.call (to_jv t) "line" [| Jv.of_int n |]
  let line_at pos (t : t) = Jv.call (to_jv t) "lineAt" [| Jv.of_int pos |]

  let to_string (t : t) =
    Jv.call (to_jv t) "toString" [||] |> Jv.to_jstr |> Jstr.to_string

  let to_jstr_array (t : t) =
    Jv.call (to_jv t) "toJSON" [||] |> Jv.to_jstr_array
end

module Line = struct
  type t = Jv.t

  let from t = Jv.Int.get t "from"
  let to_ t = Jv.Int.get t "to"
  let number t = Jv.Int.get t "number"
  let text t = Jv.Jstr.get t "text"
  let length t = Jv.Int.get t "length"
end

module StateEffect = struct
  include StateEffect

  let state_effect = lazy (Jv.get Jv.global "__CM__StateEffect")

  let define : type a. (a -> Jv.t) -> (Jv.t -> a) -> a t =
   fun a_to_jv a_of_jv ->
    let v' = Jv.call (Lazy.force state_effect) "define" [||] in
    of_jv (Tjv.conv a_to_jv a_of_jv) v'

  let define_ : type a.
      (a -> Jv.t) -> (Jv.t -> a) -> map:(a -> ChangeDesc.t -> a option) -> a t =
   fun a_to_jv a_of_jv ~map ->
    let map v changes =
      match map v changes with Some v -> a_to_jv v | None -> Jv.undefined
    in
    let o = Jv.obj [| ("map", Jv.callback ~arity:2 map) |] in
    let v' = Jv.call (Lazy.force state_effect) "define" [| o |] in
    of_jv (Tjv.conv a_to_jv a_of_jv) v'

  let is : Jv.t t -> 'a t -> bool =
   fun v ty -> Jv.call (to_jv v) "is" [| to_jv ty |] |> Jv.to_bool

  let value t ty =
    if is t ty then
      let c = conv ty in
      Some (Jv.get (to_jv t) "value" |> c.of_jv)
    else None

  let of_ t v =
    let conv = conv t in
    Jv.call (to_jv t) "of" [| conv.to_jv v |] |> of_jv conv

  let append_config () : Extension.t StateEffect.t =
    Jv.get (Lazy.force state_effect) "appendConfig"
    |> of_jv { of_jv = Extension.of_jv; to_jv = Extension.to_jv }
end

(* A compartment is a slot in the extension tree whose contents can be
   replaced later, by dispatching the effect [reconfigure] returns. *)
module Compartment : sig
  type t

  include Jv.CONV with type t := t

  val make : unit -> t
  val of_ : t -> Extension.t -> Extension.t
  val reconfigure : t -> Extension.t -> Extension.t StateEffect.t
end = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let compartment = lazy (Jv.get Jv.global "__CM__Compartment")
  let make () = Jv.new' (Lazy.force compartment) [||]

  let of_ t extension =
    Jv.call t "of" [| Extension.to_jv extension |] |> Extension.of_jv

  let reconfigure t extension =
    Jv.call t "reconfigure" [| Extension.to_jv extension |]
    |> StateEffect.of_jv (Tjv.conv Extension.to_jv Extension.of_jv)
end

module ChangeSet = struct
  include ChangeSet

  let g = lazy (Jv.get Jv.global "__CM__changeSet")
  let to_json v : Brr.Json.t = Jv.call (to_jv v) "toJSON" [||]
  let of_json json = Jv.call (Lazy.force g) "fromJSON" [| json |] |> of_jv
end

(* A ChangeSpec describes changes to the document: one replacement of
   [from]..[to_] by [insert], or several at once. *)
module ChangeSpec : sig
  type t

  include Jv.CONV with type t := t

  val create : from:int -> ?to_:int -> ?insert:string -> unit -> t
  val of_change_set : ChangeSet.t -> t
  val of_list : t list -> t
end = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let create ~from ?to_ ?insert () =
    let o = Jv.obj [||] in
    Jv.set o "from" (Jv.of_int from);
    Jv.set_if_some o "to" (Option.map Jv.of_int to_);
    Jv.set_if_some o "insert" (Option.map Jv.of_string insert);
    o

  let of_change_set x = ChangeSet.to_jv x
  let of_list l = Jv.of_list to_jv l
end

(* A TransactionSpec describes a transaction to make: the changes,
   selection and effects to apply. Dispatching one to a view, or
   [EditorState.update], produces a Transaction, which records what was
   done. *)
module TransactionSpec = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  type selection =
    | Short of { anchor : int; head : int option }
    | Selection of EditorSelection.t

  let selection_to_jv = function
    | Short { anchor; head } ->
        let o = Jv.obj [||] in
        Jv.set o "anchor" (Jv.of_int anchor);
        Jv.set_if_some o "head" (Option.map Jv.of_int head);
        o
    | Selection s -> EditorSelection.to_jv s

  let create ?(effects = []) ?selection ?changes ?scroll_into_view () =
    let o = Jv.obj [||] in
    Jv.set_if_some o "selection" (Option.map selection_to_jv selection);
    Jv.set_if_some o "changes" (Option.map ChangeSpec.to_jv changes);
    Jv.set o "effects" (Jv.of_list StateEffect.to_jv effects);
    Jv.Bool.set_if_some o "scrollIntoView" scroll_into_view;
    of_jv o
end

module EditorState = struct
  include EditorState

  let editor_state = lazy (Jv.get Jv.global "__CM__state")

  let create : ?config:EditorStateConfig.t -> unit -> t =
   fun ?(config = EditorStateConfig.undefined) () ->
    Jv.call (Lazy.force editor_state) "create"
      [| EditorStateConfig.to_jv config |]
    |> of_jv

  let doc (t : t) = Jv.get (to_jv t) "doc" |> Text.of_jv

  let field (t : t) (f : 'a StateField.t) =
    let c = StateField.conv f in
    Jv.call (to_jv t) "field" [| StateField.to_jv f |] |> c.of_jv

  let selection (v : t) = Jv.get (to_jv v) "selection" |> EditorSelection.of_jv

  let update (t : t) (specs : TransactionSpec.t list) : Transaction.t =
    Jv.call (to_jv t) "update"
      (Array.of_list (List.map TransactionSpec.to_jv specs))
    |> Transaction.of_jv
end

module StateField = struct
  include StateField

  let state_field = lazy (Jv.get Jv.global "__CM__StateField")

  let define : type a.
      ?compare:(a -> a -> bool) ->
      ?provide:(a t -> Extension.t) ->
      (a -> Jv.t) ->
      (Jv.t -> a) ->
      create:(EditorState.t -> a) ->
      update:(a -> Transaction.t -> a) ->
      a t =
   fun ?compare ?provide v_to_jv v_of_jv ~create ~update ->
    let update_wrapper v t =
      update (v_of_jv v) (Transaction.of_jv t) |> v_to_jv
    in
    let create_wrapper st = create (EditorState.of_jv st) |> v_to_jv in
    let provide =
      Option.map
        (fun f v ->
          f (StateField.of_jv { to_jv = v_to_jv; of_jv = v_of_jv } v)
          |> Extension.to_jv)
        provide
    in
    let o = Jv.obj [||] in
    Jv.set_if_some o "compare" (Option.map (Jv.callback ~arity:2) compare);
    Jv.set_if_some o "provide" (Option.map (Jv.callback ~arity:1) provide);
    Jv.set o "update" (Jv.callback ~arity:2 update_wrapper);
    Jv.set o "create" (Jv.callback ~arity:1 create_wrapper);
    let jv = Jv.call (Lazy.force state_field) "define" [| o |] in
    StateField.of_jv { to_jv = v_to_jv; of_jv = v_of_jv } jv

  let init : 'a t -> (EditorState.t -> 'a) -> Extension.t =
   fun f init ->
    let init_wrapper st = init (EditorState.of_jv st) |> (conv f).to_jv in
    let jv = Jv.call (to_jv f) "init" [| Jv.callback ~arity:1 init_wrapper |] in
    Extension.of_jv jv
end

module Facet = struct
  include Facet

  let of_ : ('i, 'o) t -> 'i -> Extension.t =
   fun v i ->
    Jv.call (to_jv v) "of" [| (to_conv v).to_jv i |] |> Extension.of_jv

  let from : ('i, 'o) t -> 'a StateField.t -> Extension.t =
   fun v f ->
    Jv.call (to_jv v) "from" [| StateField.to_jv f |] |> Extension.of_jv

  let from' : ('i, 'o) t -> 'a StateField.t -> ('a -> 'i) -> Extension.t =
   fun v f fn ->
    let wrapped_fn x = fn ((StateField.conv f).of_jv x) |> (to_conv v).to_jv in
    Jv.call (to_jv v) "from"
      [| StateField.to_jv f; Jv.callback ~arity:1 wrapped_fn |]
    |> Extension.of_jv
end

module Transaction = struct
  include Transaction

  let effects : t -> Jv.t StateEffect.t list =
   fun v ->
    Jv.get (to_jv v) "effects"
    |> Jv.to_list (StateEffect.of_jv (Tjv.conv Jv.Id.to_jv Jv.Id.of_jv))

  let changes : t -> ChangeDesc.t =
   fun v -> Jv.get (to_jv v) "changes" |> ChangeDesc.of_jv

  let state : t -> EditorState.t =
   fun v -> Jv.get (to_jv v) "state" |> EditorState.of_jv

  let doc_changed : t -> bool = fun v -> Jv.Bool.get (to_jv v) "docChanged"
end
