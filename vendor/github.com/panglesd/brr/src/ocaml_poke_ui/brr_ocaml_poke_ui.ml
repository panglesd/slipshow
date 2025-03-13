(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Fut.Result_syntax
open Brr
open Brr_io

(* Storage. Webextensions have their own mecanism, we provide a common
   API for local storage and webextension storage. *)

module Store = struct
  type t =
    { get : Jstr.t -> Jstr.t option Fut.or_error;
      set : Jstr.t -> Jstr.t -> unit Fut.or_error }

  let create ~get ~set = { get; set }
  let get s = s.get
  let set s = s.set
  let key_prefix = Jstr.v "ocaml-repl-"
  let page ?(key_prefix = key_prefix) store =
    let key k = Jstr.(key_prefix + k) in
    let get k = Fut.ok (Storage.get_item store (key k)) in
    let set k v = Fut.return (Storage.set_item store (key k) v) in
    { get; set }

  let webext ?(key_prefix = key_prefix) () =
    ignore key_prefix;
    match Jv.find_path Jv.global ["chrome"; "storage"; "local"] with
    | None ->
        let err () = Jv.throw (Jstr.v "chrome.storage.local is undefined") in
        let get _k = err () and set _k _v = err () in
        create ~get ~set
    | Some s ->
        let get k =
          let fut, set_fut = Fut.create () in
          let result r = set_fut (Ok (Jv.find_map' Jv.to_jstr r k)) in
          ignore @@ Jv.call s "get" [| Jv.of_jstr_list [k]; Jv.repr result |];
          fut
        in
        let set k v =
          let fut, set_fut = Fut.create () in
          let o = Jv.obj' [| k, Jv.of_jstr v |] in
          let result _r = set_fut (Ok ()) in
          ignore @@ Jv.call s "set" [| o; Jv.repr result |];
          fut
        in
        create ~get ~set
end

(* History data structure *)

module History = struct
  type t = { prev : Jstr.t list; focus : Jstr.t; next : Jstr.t list; }

  let v ~prev =
    let add acc e =
      let e = Jstr.trim e in
      if Jstr.is_empty e then acc else e :: acc
    in
    let focus = Jstr.empty in
    { prev = List.rev (List.fold_left add [] prev) ; focus; next = [] }

  let empty = v ~prev:[]
  let push e es =
    if Jstr.is_empty e then es else match es with
    | e' :: _ when Jstr.equal e e' -> es
    | es -> e :: es

  let entries h =
    let next = List.filter (fun s -> not (Jstr.is_empty s)) h.next in
    List.rev_append (push h.focus next) h.prev

  let add h e =
    let e = Jstr.trim e in
    if Jstr.is_empty e then h else v ~prev:(push e (entries h))

  let restart h = v ~prev:(entries h)
  let prev h current = match h.prev with
  | [] -> None
  | p :: ps ->
      let next = push (Jstr.trim current) (push h.focus h.next) in
      let next =
        if next = [] then [Jstr.empty] (* bottom can be empty *) else next
      in
      Some ({ prev = ps; focus = p; next; }, p)

  let next h current = match h.next with
  | [] -> None
  | n :: ns ->
      let prev = push (Jstr.trim current) (push h.focus h.prev) in
      Some ({ prev; focus = n; next = ns }, n)

  let sep sep = Jstr.(nl + sep + nl) (* FIXME windows ? *)
  let to_string ~sep:s h = Jstr.concat ~sep:(sep s) (entries h)
  let of_string ~sep:s hs =
    v ~prev:(List.map Jstr.trim (Jstr.cuts ~sep:(sep s) hs))
end

(* Code highlighting.

   Needs https://highlightjs.org in the page. *)

module Highlight = struct
  let el e = match Jv.find Jv.global "hljs" with
  | None -> e
  | Some hljs -> ignore @@ Jv.call hljs "highlightBlock" [| El.to_jv e |]; e
end

(* Text input.

   Auto-resizing text area with a click-through overlay for syntax
   highlighting. Needs a bit of cooperation from the styling layer. *)

module Text_input : sig
  type t
  val create : ?lang:Jstr.t -> prompt:El.t -> unit -> t
  val el : t -> El.t
  val input : t -> El.t
  val hide : t -> unit
  val show : t -> unit
  val set_has_focus : bool -> t -> unit
  val cursor_pos : t -> int option
  val set : t -> Jstr.t -> unit
  val get : t -> Jstr.t
  val update_input : t -> unit
end = struct
  type t =
    { input : El.t;   (* Transparent textarea *)
      overlay : El.t; (* Code highlighting overlay *)
      el : El.t;      (* Wrapping div (including prompt) *) }

  let hide t = El.set_inline_style El.Style.display (Jstr.v "none") t.el
  let show t = El.set_inline_style El.Style.display (Jstr.v "grid") t.el
  let create ?lang:(plang = Jstr.v "ocaml") ~prompt () =
    let highlight = Jstr.v "highlight" in
    let overlay = El.pre ~at:At.[class' highlight; class' plang] [] in
    let input = El.textarea ~at:At.[rows 1; spellcheck (Jstr.v "false")] [] in
    let div = El.div ~at:At.[class' (Jstr.v "text-input")] [input; overlay] in
    let el = El.div ~at:At.[class' (Jstr.v "input")] [prompt; div] in
    let t = { input; overlay; el } in
    hide t; t

  let el t = t.el
  let input t = t.input
  let set_has_focus focus t = El.set_has_focus focus t.input
  let auto_resize t =
    (* autoresize, we need overflow:hidden on textarea; *)
    El.set_inline_style El.Style.height (Jstr.v "auto") t.input;
    let h = El.scroll_h t.input in
    El.set_inline_style El.Style.height Jstr.(of_float h + v "px") t.input;
    El.scroll_into_view ~align_v:`End t.input

  let cursor_pos t =
    let sel_start = El.prop (El.Prop.int @@ Jstr.v "selectionStart") t.input in
    let sel_end = El.prop (El.Prop.int @@ Jstr.v "selectionEnd") t.input in
    if sel_start = sel_end then Some sel_start else None

  let set_cursor_pos t pos =
    let args = Jv.[| of_int pos ; of_int pos|] in
    ignore @@ Jv.call (El.to_jv t.input) "setSelectionRange" args

  let get t = El.prop El.Prop.value t.input
  let update_overlay t =
    El.set_children t.overlay El.[txt (get t)];
    ignore (Highlight.el t.overlay)

  let update_input t = auto_resize t; update_overlay t
  let set t s =
    El.set_prop El.Prop.value s t.input;
    update_input t;
    El.set_has_focus true t.input;
    set_cursor_pos t (Jstr.length s)
end

(* Spinner to distract our impatient brains *)

module Spinner = struct
  type t = { mutable abort : Abort.t option; el : El.t }
  let el s = s.el

  let abort s = match s.abort with
  | None -> () | Some a -> Abort.abort a; s.abort <- None

  let hide s =
    abort s; El.set_inline_style El.Style.display (Jstr.v "none") s.el

  let create () =
    let el = El.div ~at:At.[class' (Jstr.v "spinner")] [] in
    let s = { abort = None; el } in
    hide s; s

  let spin s signal =
    Fut.bind (Fut.tick ~ms:100 (* Wait for brain to notice *)) @@ fun () ->
    let rec loop dot_count next =
      Fut.bind next @@ fun () -> match Abort.Signal.aborted signal with
      | true -> Fut.ok ()
      | false ->
          let dots = Jstr.repeat dot_count (Jstr.v ".") in
          El.set_children s.el [El.txt dots];
          let next = Fut.tick ~ms:450 in
          if dot_count >= 1 then loop 0 next else loop (dot_count + 1) next
    in
    loop 1 (Fut.return ())

  let show s = match s.abort with
  | Some _a -> ()
  | None ->
      let abort = Abort.controller () in
      s.abort <- Some abort;
      El.set_inline_style El.Style.display (Jstr.v "initial") s.el;
      ignore (spin s (Abort.signal abort))
end

(* Toplevel ui *)

type t =
  { view : El.t;
    output : El.t;
    spinner : Spinner.t;
    input : Text_input.t;
    store : Store.t;
    mutable h : History.t }

(* Ui output *)

type output_kind =
  [ `Past_input | `Reply | `Warning | `Error | `Info | `Announce ]

let output_kind_to_class = function
| `Past_input -> "past-input" | `Reply -> "reply" | `Warning -> "warning"
| `Error -> "error" | `Info -> "info" | `Announce -> "announce"

let output r ~kind cs =
  let at = At.[class' (Jstr.v (output_kind_to_class kind))] in
  let li = El.li ~at cs in
  El.append_children r.output [li]

let announce_poke poke =
  let ocaml =
    let version = Brr_ocaml_poke.ocaml_version poke in
    let ocaml = Jstr.append (Jstr.v "OCaml version ") version in
    El.span ~at:At.[class' (Jstr.v "ocaml")] [El.txt ocaml]
  in
  let jsoo =
    let version = Brr_ocaml_poke.jsoo_version poke in
    let jsoo = match Jstr.is_empty version with
    | true -> Jstr.empty
    | false -> Jstr.append (Jstr.v "js_of_ocaml ") version
    in
    El.span ~at:At.[class' (Jstr.v "jsoo")] [El.txt jsoo]
  in
  El.pre [ocaml; El.txt' " "; jsoo]

let ocaml_pre s =
  if Jstr.is_empty s then [] else
  [Highlight.el (El.pre ~at:At.[class' (Jstr.v "ocaml")] [El.txt s])]

(* History handling *)

let history_sep = Jstr.v "(**)"
let history_key = Jstr.v "history"
let history_clear r = r.h <- History.empty; r.store.set history_key Jstr.empty
let history_load r =
  let* h = r.store.get history_key in
  let history = Option.value ~default:Jstr.empty h in
  r.h <- History.of_string ~sep:history_sep history;
  Fut.ok ()

let history_prev r s = match History.prev r.h s with
| None -> s | Some (h, s) -> r.h <- h; s

let history_next r s = match History.next r.h s with
| None -> s | Some (h, s) -> r.h <- h; s

let history_save r s =
  let chop_end_nl s =
    if Jstr.ends_with ~suffix:(Jstr.v "\n") s
    then Jstr.slice ~stop:(-1) s else s
  in
  r.h <- History.add r.h (chop_end_nl s);
  let h = History.to_string ~sep:history_sep r.h in
  ignore @@ Fut.map (Console.log_if_error ~use:()) @@ r.store.set history_key h

let history_clear_ui r =
  let clear = El.button El.[txt' "Clear history"] in
  let clear_act _ =
    ignore @@ Fut.map (Console.log_if_error ~use:()) @@ history_clear r
  in
  ignore (Ev.listen Ev.click clear_act (El.as_target clear));
  clear

let history_keyboard_moves r key =
  let first_line_end s = match Jstr.find_sub ~sub:Jstr.nl s with
  | None -> Jstr.length s | Some i -> i
  in
  let last_line_start s = match Jstr.find_last_sub ~sub:Jstr.nl s with
  | None -> 0
  | Some i when i = Jstr.length s - 1 -> 0
  | Some i -> i + 1
  in
  let k = Ev.as_type key in
  let (key_code : int) = Jv.Int.get (Ev.to_jv key) "keyCode" in (* FIXME *)
  let txt = Text_input.get r.input in
  match key_code with
  | 38 ->
      let do_prev =
        Ev.Keyboard.ctrl_key k || match Text_input.cursor_pos r.input with
        | None -> false
        | Some cursor when cursor > first_line_end txt -> false
        | Some _cursor -> true
      in
      if not do_prev then () else
      (Ev.prevent_default key; Text_input.set r.input (history_prev r txt))
  | 40 ->
      let do_next =
        Ev.Keyboard.ctrl_key k || match Text_input.cursor_pos r.input with
        | None -> false
        | Some cursor when cursor < last_line_start txt -> false
        | Some _cursor -> true
      in
      if not do_next then () else
      (Ev.prevent_default key; Text_input.set r.input (history_next r txt))
  | _ -> ()

(* Input handling *)

let prompt () = El.span ~at:At.[class' (Jstr.v "prompt")] El.[txt' "#"]
let lock_input r = Text_input.hide r.input; Spinner.show r.spinner
let unlock_input r =
  Spinner.hide r.spinner;
  Text_input.show r.input;
  Text_input.update_input r.input;
  Text_input.set_has_focus true r.input

let handle_text_input r poke _e =
  let i = Text_input.get r.input in
  let enter = Jstr.v ";;\n" and enter_win = Jstr.v ";;\r\n" in
  let submit =
    Jstr.ends_with ~suffix:enter i || Jstr.ends_with ~suffix:enter_win i
  in
  if not submit then Text_input.update_input r.input else
  begin
    history_save r i;
    output r ~kind:`Past_input (prompt () :: ocaml_pre i);
    lock_input r;
    Text_input.set r.input Jstr.empty;
    ignore @@
    let* out = Fut.map (Result.map Jv.to_jstr) (Brr_ocaml_poke.eval poke i) in
    output r ~kind:`Reply (ocaml_pre out);
    unlock_input r;
    Fut.ok ()
  end

let use_ml_file r poke file =
  let use = Jstr.(v "#use \"" + File.name file + v "\";;") in
  output r ~kind:`Past_input (prompt () :: ocaml_pre use);
  let* text = Blob.text (File.as_blob file) in
  let* out = Brr_ocaml_poke.use poke text in
  let out = Jv.to_jstr out in
  output r ~kind:`Reply (ocaml_pre out);
  Fut.ok ()

let use_ml_files r poke files =
  let rec loop = function
  | f :: fs -> let* () = use_ml_file r poke f in loop fs
  | [] -> Fut.ok ()
  in
  let finish result = Console.log_if_error ~use:() result; unlock_input r in
  lock_input r; ignore @@ Fut.map finish (loop files)

let use_ml_ui r poke =
  let on_change i =
    let files = El.Input.files i in
    El.set_prop El.Prop.value Jstr.empty i;
    use_ml_files r poke files
  in
  (* The hidden file input + button trick *)
  let i = El.input ~at:At.[type' (Jstr.v "file")] () in
  let b = El.button [ El.txt' "#use \"…\"" ] in
  El.set_inline_style El.Style.display (Jstr.v "none") i;
  ignore (Ev.listen Ev.click (fun _e -> El.click i) (El.as_target b));
  ignore (Ev.listen Ev.change (fun _e -> on_change i) (El.as_target i));
  El.span [i; b]

let use_ml_on_file_drag_and_drop ?drop_target r poke =
  let on_drop e =
    Ev.prevent_default e;
    match Ev.Drag.data_transfer (Ev.as_type e) with
    | None -> ()
    | Some dt ->
        let items = Ev.Data_transfer.(Item_list.items (items dt)) in
        let files = List.filter_map Ev.Data_transfer.Item.get_file items in
        use_ml_files r poke files
  in
  let on_dragover e = Ev.prevent_default e in
  let t = match drop_target with None -> El.as_target r.view | Some t -> t in
  ignore (Ev.listen Ev.dragover on_dragover t);
  ignore (Ev.listen Ev.drop on_drop t);
  ()

(* Creating and running the ui *)

let create ?(store = Store.page (Storage.local G.window)) view =
  let output = El.ol [] in
  let spinner = Spinner.create () in
  let input = Text_input.create ~prompt:(prompt ()) () in
  let r = { view; output; input; spinner; store; h = History.v ~prev:[] } in
  El.set_children view [output; Text_input.el input; Spinner.el spinner];
  El.set_class (Jstr.v "ocaml-ui") true view;
  let* () = history_load r in
  Fut.ok r

let buttons ?(buttons = []) r poke =
  let panel = El.div ~at:At.[class' (Jstr.v "buttons")] [] in
  let clear = history_clear_ui r in
  let use_ml = use_ml_ui r poke in
  El.set_children panel (buttons @ [clear; use_ml]);
  panel

let setup_poke_io ?drop_target r poke =
  let input = El.as_target (Text_input.input r.input) in
  ignore (Ev.listen Ev.input (handle_text_input r poke) input);
  ignore (Ev.listen Ev.keydown (history_keyboard_moves r) input);
  use_ml_on_file_drag_and_drop ?drop_target r poke

let run ?drop_target ?buttons:bs r poke =
  let buttons = buttons ?buttons:bs r poke in
  El.append_children r.view [buttons];
  setup_poke_io ?drop_target r poke;
  output r ~kind:`Announce [announce_poke poke];
  Text_input.show r.input;
  Text_input.set_has_focus true r.input
