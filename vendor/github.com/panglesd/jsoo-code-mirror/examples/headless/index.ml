(* Transactions without a view. A TransactionSpec says what to do; the
   state's [update] does it and returns a Transaction: what changed, the
   effects that ran, and the state that resulted. None of this needs an
   editor on the page, so the results are printed as plain text. *)

open Code_mirror
open State
open Brr

let show lines =
  El.append_children (Document.body G.document)
    [ El.pre (List.map (fun l -> El.txt' (l ^ "\n")) lines) ]

let doc_of state =
  String.concat "\n"
    (Array.to_list
       (Array.map Jstr.to_string (Text.to_jstr_array (EditorState.doc state))))

let () =
  let config = EditorStateConfig.create ~doc:"one\ntwo\nthree" () in
  let state = EditorState.create ~config () in
  (* Insert a line at the end and move the cursor there. *)
  let insert =
    TransactionSpec.create
      ~changes:
        (ChangeSpec.create
           ~from:(String.length "one\ntwo\nthree")
           ~insert:"\nfour" ())
      ~selection:
        (TransactionSpec.Short
           { anchor = String.length "one\ntwo\nthree\nfour"; head = None })
      ()
  in
  let tr = EditorState.update state [ insert ] in
  let state' = Transaction.state tr in
  (* A selection-only spec changes no text. *)
  let move =
    TransactionSpec.create
      ~selection:(TransactionSpec.Short { anchor = 0; head = None })
      ()
  in
  let tr' = EditorState.update state' [ move ] in
  let head st =
    SelectionRange.head
      (List.hd (EditorSelection.ranges (EditorState.selection st)))
  in
  show
    [
      "before:          " ^ String.escaped (doc_of state);
      Printf.sprintf "insert:          doc_changed=%b  doc=%s  cursor=%d"
        (Transaction.doc_changed tr)
        (String.escaped (doc_of state'))
        (head state');
      Printf.sprintf "move cursor:     doc_changed=%b  doc=%s  cursor=%d"
        (Transaction.doc_changed tr')
        (String.escaped (doc_of (Transaction.state tr')))
        (head (Transaction.state tr'));
      Printf.sprintf "original state:  doc=%s (states are immutable)"
        (String.escaped (doc_of state));
    ]
