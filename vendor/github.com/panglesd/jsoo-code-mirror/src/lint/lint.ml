open Code_mirror

let lint = Jv.get Jv.global "__CM__lint"

module Action = struct
  type t = Jv.t

  let create ~name f =
    let f' view from to_ =
      let view = View.EditorView.of_jv view in
      let from = Jv.to_int from in
      let to_ = Jv.to_int to_ in
      let result = f ~view ~from ~to_ in
      result
    in
    let o = Jv.obj [||] in
    Jv.Jstr.set o "name" (Jstr.v name);
    Jv.set o "apply" (Jv.callback ~arity:3 f');
    o

  include (Jv.Id : Jv.CONV with type t := t)
end

module Diagnostic = struct
  type t = Jv.t

  let from t = Jv.Int.get t "from"
  let to_ t = Jv.Int.get t "to"

  type severity = Hint | Info | Warning | Error

  let severity_of_string = function
    | "hint" -> Hint
    | "info" -> Info
    | "warning" -> Warning
    | "error" -> Error
    | _ -> raise (Invalid_argument "Unknown severity level")

  let severity_to_string = function
    | Hint -> "hint"
    | Info -> "info"
    | Warning -> "warning"
    | Error -> "error"

  let severity t =
    Jv.Jstr.get t "severity" |> Jstr.to_string |> severity_of_string

  let create ?source ?actions ~from ~to_ ~severity ~message () =
    let o = Jv.obj [||] in
    Jv.Int.set o "from" from;
    Jv.Int.set o "to" to_;
    Jv.Jstr.set o "severity" (severity_to_string severity |> Jstr.v);
    Jv.Jstr.set o "message" (Jstr.v message);
    Jv.Jstr.set_if_some o "source" (Option.map Jstr.v source);
    Jv.set_if_some o "actions" (Option.map (Jv.of_list Action.to_jv) actions);
    o

  let source t = Jv.Jstr.find t "source"
  let message t = Jv.Jstr.get t "message"
  let actions t = Option.map (Jv.to_list Action.to_jv) (Jv.find t "actions")

  include (Jv.Id : Jv.CONV with type t := t)
end

let create ?delay (source : View.EditorView.t -> Diagnostic.t list Fut.t) =
  let o =
    match delay with
    | None -> Jv.obj [||]
    | Some d -> Jv.obj [| ("delay", Jv.of_int d) |]
  in
  let source' view =
    let fut =
      Fut.map (Jv.of_list Diagnostic.to_jv)
      @@ source (View.EditorView.of_jv view)
    in
    Fut.to_promise ~ok:Fun.id (Fut.map Result.ok fut)
  in
  let ext = Jv.call lint "linter" [| Jv.callback ~arity:1 source'; o |] in
  Code_mirror.Extension.of_jv ext
