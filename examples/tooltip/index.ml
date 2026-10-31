(* Hover tooltips: hovering over a word shows it, along with the space
   the editor gave the tooltip when it positioned it. The tooltip appears
   after 100ms rather than the default 300ms, and typing hides it. *)

open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv

let is_word_char c =
  Char.equal c '_' || Char.lowercase_ascii c <> Char.uppercase_ascii c

(* The word around [pos] in [s], as [(from, to_)], if there is one. *)
let word_at s pos =
  let n = String.length s in
  let rec back i =
    if i > 0 && is_word_char s.[i - 1] then back (i - 1) else i
  in
  let rec fwd i = if i < n && is_word_char s.[i] then fwd (i + 1) else i in
  let from = back pos and to_ = fwd pos in
  if from < to_ then Some (from, to_) else None

let tooltip word ~pos ~end_ =
  let space = El.div [] in
  let dom = El.div [ El.div [ El.txt' word ]; space ] in
  El.set_inline_style (Jstr.v "padding") (Jstr.v "4px 8px") dom;
  let positioned { Tooltip.Tooltip_view.left; right; top; bottom } =
    El.set_children space
      [
        El.txt' (Printf.sprintf "space: %d x %d" (right - left) (bottom - top));
      ]
  in
  Tooltip.Tooltip.create ~pos ~end_ ~above:true
    ~create:(fun _view -> Tooltip.Tooltip_view.create ~dom ~positioned ())
    ()

let source ~view ~pos ~side:_ =
  let doc = Text.to_string (EditorState.doc (EditorView.state view)) in
  Fut.return
    (Option.map
       (fun (from, to_) ->
         tooltip (String.sub doc from (to_ - from)) ~pos:from ~end_:to_)
       (word_at doc pos))

let () =
  let hover =
    Tooltip.hover_tooltip
      ~config:(Tooltip.hover_config ~hover_time:100 ~hide_on_change:true ())
      source
  in
  let config =
    EditorStateConfig.create
      ~doc:"Hover over any word in this editor to see a tooltip.\n"
      ~extensions:(Extension.of_list [ basic_setup; hover ])
      ()
  in
  let state = EditorState.create ~config () in
  ignore
    (EditorView.create
       ~config:
         (EditorViewConfig.create ~state ~parent:(Document.body G.document) ())
       ())
