open Code_mirror
module RegExp = RegExp

let autocomplete = Jv.get Jv.global "__CM__autocomplete"

module Completion = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let set_if_some_string t s v = Jv.Jstr.set_if_some t s (Option.map Jstr.v v)
  let set_string t s v = Jv.Jstr.set t s (Jstr.v v)

  let create ~label ?detail ?info ?apply ?type_ ?boost () =
    let o = Jv.obj [||] in
    set_string o "label" label;
    set_if_some_string o "detail" detail;
    set_if_some_string o "info" info;
    Jv.set_if_some o "apply" apply;
    set_if_some_string o "type" type_;
    Jv.Int.set_if_some o "boost" boost;
    o
end

module Context = struct
  type t = Jv.t
  (** Completion context *)

  include (Jv.Id : Jv.CONV with type t := t)

  let state t = Jv.get t "state" |> Editor.State.of_jv
  let pos t = Jv.Int.get t "pos"
  let explicit t = Jv.Bool.get t "explicit"

  let token_before t types =
    let jv = Jv.call t "tokenBefore" [| Jv.of_list Jv.of_string types |] in
    if Jv.is_none jv then None else Some jv

  let match_before t regex =
    let jv = Jv.call t "matchBefore" [| RegExp.to_jv regex |] in
    if Jv.is_none jv then None else Some jv

  let aborted t = Jv.Bool.get t "aborted"
end

module Result = struct
  type t = Jv.t
  (** Completion result *)

  include (Jv.Id : Jv.CONV with type t := t)

  let create ~from ?to_ ~options ?span ?filter () =
    let o = Jv.obj [||] in
    Jv.Int.set o "from" from;
    Jv.Int.set_if_some o "to" to_;
    Jv.set o "options" (Jv.of_list Completion.to_jv options);
    Jv.set_if_some o "span" (Option.map RegExp.to_jv span);
    Jv.Bool.set_if_some o "filter" filter;
    o
end

module Source = struct
  type t = Jv.t

  include (Jv.Id : Jv.CONV with type t := t)

  let create (src : Context.t -> Result.t option Fut.t) =
    let f ctx =
      let fut = Fut.map (fun v -> Ok v) @@ src (Context.of_jv ctx) in
      Fut.to_promise fut ~ok:(fun t ->
          Option.value ~default:Jv.null (Option.map Result.to_jv t))
    in
    Jv.repr f

  let from_list (l : Completion.t list) =
    Jv.call autocomplete "completeFromList" [| Jv.of_jv_list l |] |> of_jv
end

type config = Jv.t

let config ?activate_on_typing ?override ?max_rendered_options ?default_key_map
    ?above_cursor ?option_class ?icons ?add_to_options () =
  let o = Jv.obj [||] in
  Jv.Bool.set_if_some o "activateOnTyping" activate_on_typing;
  Jv.set_if_some o "override" (Option.map (fun v -> Jv.of_jv_list v) override);
  Jv.Int.set_if_some o "maxRenderedOptions" max_rendered_options;
  Jv.Bool.set_if_some o "defaultKeyMap" default_key_map;
  Jv.Bool.set_if_some o "aboveCursor" above_cursor;
  Jv.set_if_some o "optionClass" option_class;
  Jv.Bool.set_if_some o "icons" icons;
  Jv.set_if_some o "addToOptions" add_to_options;
  o

let create ?(config = Jv.null) () =
  Extension.of_jv @@ Jv.call autocomplete "autocompletion" [| config |]

(* type status = Active | Pending

   let status state =

   val status : Editor.State.t -> status option
   (** Gets the current completion status *)

   val current_completions : Editor.State.t -> Completion.t list
   (** Returns the current available completions *)

   val selected_completion : Editor.State.t -> Completion.t option
   * Returh the currently selected completion if any *)
