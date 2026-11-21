(* Compartments: parts of the configuration that can be swapped at run
   time. Two buttons reconfigure two compartments: one holds the
   line-number gutter, whose formatter offsets the numbers, the other
   holds line wrapping. Each click dispatches a TransactionSpec carrying
   the effect Compartment.reconfigure returns. *)

open Code_mirror
open State
open View
open Brr

let basic_setup = Jv.get Jv.global "__CM__basic_setup" |> Extension.of_jv
let numbers = Compartment.make ()
let wrapping = Compartment.make ()
let offset = ref 0
let wrapped = ref true

let gutter () =
  line_numbers ~format_number:(fun n _state -> string_of_int (n + !offset)) ()

let wrap () =
  if !wrapped then EditorView.line_wrapping () else Extension.of_list []

let button label on_click =
  let b = El.button [ El.txt' label ] in
  ignore (Ev.listen Ev.click (fun _ -> on_click ()) (El.as_target b));
  b

let () =
  let doc =
    "Line numbers start at 1 until you press the button; then this editor\n\
     numbers its lines as if it continued another.\n\
     Long lines wrap until the other button turns wrapping off. This line is \
     deliberately long, and the editor deliberately narrow, so that it has to \
     wrap: with wrapping off it runs past the right edge and the editor \
     scrolls sideways instead."
  in
  let config =
    EditorStateConfig.create ~doc
      ~extensions:
        (Extension.of_list
           [
             basic_setup;
             Compartment.of_ numbers (gutter ());
             Compartment.of_ wrapping (wrap ());
           ])
      ()
  in
  let state = EditorState.create ~config () in
  let parent = El.div [] in
  (* Narrow enough that the long line has to wrap. *)
  El.set_inline_style (Jstr.v "max-width") (Jstr.v "40em") parent;
  let reconfigure view comp exts =
    EditorView.dispatch view
      (TransactionSpec.create
         ~effects:[ StateEffect.any (Compartment.reconfigure comp exts) ]
         ())
  in
  let view =
    EditorView.create ~config:(EditorViewConfig.create ~state ~parent ()) ()
  in
  let controls =
    El.p
      [
        button "Number from 100" (fun () ->
            offset := if !offset = 0 then 99 else 0;
            reconfigure view numbers (gutter ()));
        El.txt' " ";
        button "Toggle wrapping" (fun () ->
            wrapped := not !wrapped;
            reconfigure view wrapping (wrap ()));
      ]
  in
  El.append_children (Document.body G.document) [ controls; parent ]
