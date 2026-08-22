type key_trace =
  | Key of string Cmarkit.node * Cmarkit.Attributes.value Cmarkit.node option
  | Value of string Cmarkit.node * Cmarkit.Attributes.value Cmarkit.node
  | Class of string Cmarkit.node
  | Id of string Cmarkit.node

type attribute_trace = Cmarkit.Attributes.t * key_trace option
type inline_trace = Cmarkit.Inline.t list
type block_trace = Cmarkit.Block.t list

type trace = {
  attribute : attribute_trace option;
  inline : inline_trace;
  block : block_trace;
}

val get_leave :
  positionEncoding:[ `UTF16 | `UTF8 ] ->
  source:string ->
  path:Fpath.t ->
  Linol_lwt.Position.t ->
  Cmarkit.Doc.t ->
  trace

val get_target :
  positionEncoding:[ `UTF16 | `UTF8 ] ->
  source:string ->
  path:Fpath.t ->
  Linol_lwt.Position.t ->
  Slipshow.Ast.Action_plan.t ->
  string option
(** Finds if we are in an action's argument that would correspond to a target *)
