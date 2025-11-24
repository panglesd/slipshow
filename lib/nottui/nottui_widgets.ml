open Lwd.Infix
open Notty
open Nottui

let empty_lwd = Lwd.return Ui.empty
let (mini, maxi, clampi) = Lwd_utils.(mini, maxi, clampi)

let string ?(attr=A.empty) str =
  let control_character_index str i =
    let len = String.length str in
    let i = ref i in
    while let i = !i in i < len && str.[i] >= ' ' do
      incr i;
    done;
    if !i = len then raise Not_found;
    !i
  in
  let rec split str i =
    match control_character_index str i with
    | j ->
      let img = I.string attr (String.sub str i (j - i)) in
      img :: split str (j + 1)
    | exception Not_found ->
      [I.string attr
         (if i = 0 then str
          else String.sub str i (String.length str - i))]
  in
  Ui.atom (I.vcat (split str 0))

let int ?attr x = string ?attr (string_of_int x)
let bool ?attr x = string ?attr (string_of_bool x)
let float_ ?attr x = string ?attr (string_of_float x)

let printf ?attr fmt =
  Printf.ksprintf (string ?attr) fmt

let fmt ?attr fmt =
  Format.kasprintf (string ?attr) fmt

let kprintf k ?attr fmt =
  Printf.ksprintf (fun str -> k (string ?attr str)) fmt

let kfmt k ?attr fmt =
  Format.kasprintf (fun str -> k (string ?attr str)) fmt

let attr_menu_main = A.(bg green ++ fg black)
let attr_menu_sub = A.(bg lightgreen ++ fg black)
let attr_clickable = A.(bg lightblue)

type window_manager = {
  overlays: ui Lwd.t Lwd_table.t;
  view: ui Lwd.t;
}

let window_manager base =
  let overlays =
    Lwd_table.make ()
  in
  let composition =
    Lwd.join (Lwd_table.reduce (Lwd_utils.lift_monoid Ui.pack_z) overlays)
  in
  let view =
    Lwd.map2 base composition ~f:begin fun base composite ->
      Ui.join_z base (Ui.resize_to (Ui.layout_spec base) composite)
    end
  in
  { overlays; view }

let window_manager_view wm = wm.view
let window_manager_overlays wm = wm.overlays

let menu_overlay wm g ?(dx=0) ?(dy=0) body around =
  let sensor ~x ~y ~w ~h () =
    let row = Lwd_table.append (window_manager_overlays wm) in
    let h_pad = match Gravity.h g with
      | `Negative -> Ui.space (x + dx) 0
      | `Neutral  -> Ui.space (x + dx + w / 2) 0
      | `Positive -> Ui.space (x + dx + w) 0
    in
    let v_pad = match Gravity.v g with
      | `Negative -> Ui.space 0 (y + dy)
      | `Neutral  -> Ui.space 0 (y + dy + h / 2)
      | `Positive -> Ui.space 0 (y + dy + h)
    in
    let view = Lwd.map body ~f:begin fun body ->
        let body =
          let pad = Ui.space 1 0 in Ui.join_x pad (Ui.join_x body pad)
        in
        let bg =
          Ui.resize_to (Ui.layout_spec body) ~bg:A.(bg lightgreen) Ui.empty
        in
        let catchall = Ui.mouse_area
            (fun ~x:_ ~y:_ -> function
               | `Left -> Lwd_table.remove row; `Handled
               | _ -> `Handled)
            (Ui.resize ~sw:1 ~sh:1 Ui.empty)
        in
        Ui.join_z catchall @@
        Ui.join_y v_pad @@
        Ui.join_x h_pad @@
        Ui.join_z bg body
      end
    in
    Lwd_table.set row view
  in
  Ui.transient_sensor sensor around

(*let menu_overlay wm ?(dx=0) ?(dy=0) handler body =
  let refresh = Lwd.var () in
  let clicked = ref false in
  Lwd.map' body @@ fun body ->
  let body = let pad = Ui.space 1 0 in Ui.join_x pad (Ui.join_x body pad) in
  let bg =
    Ui.resize_to (Ui.layout_spec body) ~bg:A.(bg lightgreen) Ui.empty
  in
  let click_handler ~x:_ ~y:_ = function
    | `Left -> clicked := true; Lwd.set refresh (); `Handled
    | _ -> `Unhandled
  in
  let ui = Ui.mouse_area click_handler (Ui.join_z bg body) in
  if !clicked then (
    clicked := false;
    let sensor ~x ~y ~w:_ ~h () =
      let row = Lwd_table.append (window_manager_overlays wm) in
      let h_pad = Ui.space (x + dx) 0 in
      let v_pad = Ui.space 0 (y + h + dy) in
      let view = Lwd.map' (handler ()) @@ fun view ->
        let catchall =
          Ui.mouse_area
            (fun ~x:_ ~y:_ -> function
               | `Left -> Lwd_table.remove row; `Handled
               | _ -> `Handled)
            (Ui.resize ~sw:1 ~sh:1 Ui.empty)
        in
        Ui.join_z catchall (Ui.join_y v_pad (Ui.join_x h_pad view))
      in
      Lwd_table.set row view
    in
    Ui.transient_sensor sensor ui
  ) else ui*)

let scroll_step = 1

type scroll_state = {
  position: int;
  bound : int;
  visible : int;
  total : int;
}

let default_scroll_state = { position = 0; bound = 0; visible = 0; total = 0 }

let vscroll_area ~state ~change t =
  let visible = ref (-1) in
  let total = ref (-1) in
  let scroll state delta =
    let position = state.position + delta in
    let position = clampi position ~min:0 ~max:state.bound in
    if position <> state.position then
      change `Action {state with position};
    `Handled
  in
  let focus_handler state = function
    (*| `Arrow `Left , _ -> scroll (-scroll_step) 0*)
    (*| `Arrow `Right, _ -> scroll (+scroll_step) 0*)
    | `Arrow `Up   , [] -> scroll state (-scroll_step)
    | `Arrow `Down , [] -> scroll state (+scroll_step)
    | `Page `Up, [] -> scroll state ((-scroll_step) * 8)
    | `Page `Down, [] -> scroll state ((+scroll_step) * 8)
    | _ -> `Unhandled
  in
  let scroll_handler state ~x:_ ~y:_ = function
    | `Scroll `Up   -> scroll state (-scroll_step)
    | `Scroll `Down -> scroll state (+scroll_step)
    | _ -> `Unhandled
  in
  Lwd.map2 t state ~f:begin fun t state ->
    t
    |> Ui.shift_area 0 state.position
    |> Ui.resize ~h:0 ~sh:1
    |> Ui.size_sensor (fun ~w:_ ~h ->
        let tchange =
          if !total <> (Ui.layout_spec t).Ui.h
          then (total := (Ui.layout_spec t).Ui.h; true)
          else false
        in
        let vchange =
          if !visible <> h
          then (visible := h; true)
          else false
        in
        if tchange || vchange then
          change `Content {state with visible = !visible; total = !total;
                                      bound = maxi 0 (!total - !visible); }
      )
    |> Ui.mouse_area (scroll_handler state)
    |> Ui.keyboard_area (focus_handler state)
  end

let scroll_area ?(offset=0,0) t =
  let offset = Lwd.var offset in
  let scroll d_x d_y =
    let s_x, s_y = Lwd.peek offset in
    let s_x = maxi 0 (s_x + d_x) in
    let s_y = maxi 0 (s_y + d_y) in
    Lwd.set offset (s_x, s_y);
    `Handled
  in
  let focus_handler = function
    | `Arrow `Left , [] -> scroll (-scroll_step) 0
    | `Arrow `Right, [] -> scroll (+scroll_step) 0
    | `Arrow `Up   , [] -> scroll 0 (-scroll_step)
    | `Arrow `Down , [] -> scroll 0 (+scroll_step)
    | `Page `Up, [] -> scroll 0 ((-scroll_step) * 8)
    | `Page `Down, [] -> scroll 0 ((+scroll_step) * 8)
    | _ -> `Unhandled
  in
  let scroll_handler ~x:_ ~y:_ = function
    | `Scroll `Up   -> scroll 0 (-scroll_step)
    | `Scroll `Down -> scroll 0 (+scroll_step)
    | _ -> `Unhandled
  in
  Lwd.map2 t (Lwd.get offset) ~f:begin fun t (s_x, s_y) ->
    t
    |> Ui.shift_area s_x s_y
    |> Ui.mouse_area scroll_handler
    |> Ui.keyboard_area focus_handler
  end

let main_menu_item wm text f =
  let text = string ~attr:attr_menu_main (" " ^ text ^ " ") in
  let refresh = Lwd.var () in
  let overlay = ref false in
  let on_click ~x:_ ~y:_ = function
    | `Left ->
      overlay := true;
      Lwd.set refresh ();
      `Handled
    | _ -> `Unhandled
  in
  Lwd.map (Lwd.get refresh) ~f:begin fun () ->
    let ui = Ui.mouse_area on_click text in
    if !overlay then (
      overlay := false;
      menu_overlay wm (Gravity.make ~h:`Negative ~v:`Positive) (f ()) ui
    ) else ui
  end

let sub_menu_item wm text f =
  let text = string ~attr:attr_menu_sub text in
  let refresh = Lwd.var () in
  let overlay = ref false in
  let on_click ~x:_ ~y:_ = function
    | `Left ->
      overlay := true;
      Lwd.set refresh ();
      `Handled
    | _ -> `Unhandled
  in
  Lwd.map (Lwd.get refresh) ~f:begin fun () ->
    let ui = Ui.mouse_area on_click text in
    if !overlay then (
      overlay := false;
      menu_overlay wm (Gravity.make ~h:`Positive ~v:`Negative) (f ()) ui
    ) else ui
  end

let sub_entry text f =
  let text = string ~attr:attr_menu_sub text in
  let on_click ~x:_ ~y:_ = function
    | `Left -> f (); `Handled
    | _ -> `Unhandled
  in
  Ui.mouse_area on_click text

type pane_state =
  | Split of { pos: int; max: int }
  | Re_split of { pos: int; max: int; at: int }

let h_pane left right =
  let state_var = Lwd.var (Split {pos = 5; max = 10}) in
  let render state (l, r) =
    let (Split {pos; max} | Re_split {pos; max; _}) = state in
    let l = Ui.resize ~w:0 ~h:0 ~sh:1 ~sw:pos l in
    let r = Ui.resize ~w:0 ~h:0 ~sh:1 ~sw:(max - pos) r in
    let splitter =
      Ui.resize ~bg:Notty.A.(bg lightyellow) ~w:1 ~h:0 ~sw:0 ~sh:1 Ui.empty
    in
    let splitter =
      Ui.mouse_area (fun ~x:_ ~y:_ -> function
          | `Left ->
            `Grab (
              (fun ~x ~y:_ ->
                 match Lwd.peek state_var with
                 | Split {pos; max} ->
                   Lwd.set state_var (Re_split {pos; max; at = x})
                 | Re_split {pos; max; at} ->
                   if at <> x then
                     Lwd.set state_var (Re_split {pos; max; at = x})
              ),
              (fun ~x:_ ~y:_ -> ())
            )
          | _ -> `Unhandled
        ) splitter
    in
    let ui = Ui.join_x l (Ui.join_x splitter r) in
    let ui = Ui.resize ~w:10 ~h:10 ~sw:1 ~sh:1 ui in
    let ui = match state with
      | Split _ -> ui
      | Re_split {at; _} ->
        Ui.transient_sensor (fun ~x ~y:_ ~w ~h:_ () ->
            let newpos = clampi (at - x) ~min:0 ~max:w in
            Lwd.set state_var (Split {pos = newpos; max = w})
          ) ui
    in
    ui
  in
  Lwd.map2 ~f:render (Lwd.get state_var) (Lwd.pair left right)

let v_pane top bot =
  let state_var = Lwd.var (Split {pos = 5; max = 10}) in
  let render state (top, bot) =
    let (Split {pos; max} | Re_split {pos; max; _}) = state in
    let top = Ui.resize ~w:0 ~h:0 ~sw:1 ~sh:pos top in
    let bot = Ui.resize ~w:0 ~h:0 ~sw:1 ~sh:(max - pos) bot in
    let splitter =
      Ui.resize ~bg:Notty.A.(bg lightyellow) ~w:0 ~h:1 ~sw:1 ~sh:0 Ui.empty
    in
    let splitter =
      Ui.mouse_area (fun ~x:_ ~y:_ -> function
          | `Left ->
            `Grab (
              (fun ~x:_ ~y ->
                 match Lwd.peek state_var with
                 | Split {pos; max} ->
                   Lwd.set state_var (Re_split {pos; max; at = y})
                 | Re_split {pos; max; at} ->
                   if at <> y then
                     Lwd.set state_var (Re_split {pos; max; at = y})
              ),
              (fun ~x:_ ~y:_ -> ())
            )
          | _ -> `Unhandled
        ) splitter
    in
    let ui = Ui.join_y top (Ui.join_y splitter bot) in
    let ui = Ui.resize ~w:10 ~h:10 ~sw:1 ~sh:1 ui in
    let ui = match state with
      | Split _ -> ui
      | Re_split {at; _} ->
        Ui.transient_sensor (fun ~x:_ ~y ~w:_ ~h () ->
            let newpos = clampi (at - y) ~min:0 ~max:h in
            Lwd.set state_var (Split {pos = newpos; max = h})
          ) ui
    in
    ui
  in
  Lwd.map2 ~f:render (Lwd.get state_var) (Lwd.pair top bot)

let sub' str p l =
  if p = 0 && l = String.length str
  then str
  else String.sub str p l

let edit_field ?(focus=Focus.make()) state ~on_change ~on_submit =
  let update focus_h focus (text, pos) =
    let pos = clampi pos ~min:0 ~max:(String.length text) in
    let content =
      Ui.atom @@ I.hcat @@
      if Focus.has_focus focus then (
        let attr = attr_clickable in
        let len = String.length text in
        (if pos >= len
         then [I.string attr text]
         else [I.string attr (sub' text 0 pos)])
        @
        (if pos < String.length text then
           [I.string A.(bg lightred) (sub' text pos 1);
            I.string attr (sub' text (pos + 1) (len - pos - 1))]
         else [I.string A.(bg lightred) " "]);
      ) else
        [I.string A.(st underline) (if text = "" then " " else text)]
    in
    let handler = function
      | `ASCII 'U', [`Ctrl] -> on_change ("", 0); `Handled (* clear *)
      | `Escape, [] -> Focus.release focus_h; `Handled
      | `ASCII k, _ ->
        let text =
          if pos < String.length text then (
            String.sub text 0 pos ^ String.make 1 k ^
            String.sub text pos (String.length text - pos)
          ) else (
            text ^ String.make 1 k
          )
        in
        on_change (text, (pos + 1));
        `Handled
      | `Backspace, _ ->
        let text =
          if pos > 0 then (
            if pos < String.length text then (
              String.sub text 0 (pos - 1) ^
              String.sub text pos (String.length text - pos)
            ) else if String.length text > 0 then (
              String.sub text 0 (String.length text - 1)
            ) else text
          ) else text
        in
        let pos = maxi 0 (pos - 1) in
        on_change (text, pos);
        `Handled
      | `Enter, _ -> on_submit (text, pos); `Handled
      | `Arrow `Left, [] ->
        let pos = mini (String.length text) pos in
        if pos > 0 then (
          on_change (text, pos - 1);
          `Handled
        )
        else `Unhandled
      | `Arrow `Right, [] ->
        let pos = pos + 1 in
        if pos <= String.length text
        then (on_change (text, pos); `Handled)
        else `Unhandled
      | _ -> `Unhandled
    in
    Ui.keyboard_area ~focus handler content
  in
  let node =
    Lwd.map2 ~f:(update focus) (Focus.status focus) state
  in
  let mouse_grab (text, pos) ~x ~y:_ = function
    | `Left ->
      if x <> pos then on_change (text, x);
      Nottui.Focus.request focus;
      `Handled
    | _ -> `Unhandled
  in
  Lwd.map2 state node ~f:begin fun state content ->
    Ui.mouse_area (mouse_grab state) content
  end

(** Tab view, where exactly one element of [l] is shown at a time. *)
let tabs (tabs: (string * (unit -> Ui.t Lwd.t)) list) : Ui.t Lwd.t =
  match tabs with
  | [] -> Lwd.return Ui.empty
  | _ ->
    let cur = Lwd.var 0 in
    Lwd.get cur >>= fun idx_sel ->
    let _, f = List.nth tabs idx_sel in
    let tab_bar =
      tabs
      |> List.mapi
        (fun i (s,_) ->
           let attr = if i = idx_sel then A.(st underline) else A.empty in
           let tab_annot = printf ~attr "[%s]" s in
           Ui.mouse_area
             (fun ~x:_ ~y:_ l -> if l=`Left then (Lwd.set cur i; `Handled) else `Unhandled)
             tab_annot)
      |> Ui.hcat
    in
    f() >|= Ui.join_y tab_bar

(** Horizontal/vertical box. We fill lines until there is no room,
    and then go to the next ligne. All widgets in a line are considered to
    have the same height.
    @param width dynamic width  (default 80)
*)
let flex_box ?(w=Lwd.return 80) (l: Ui.t Lwd.t list) : Ui.t Lwd.t =
  Lwd_utils.flatten_l l >>= fun l ->
  w >|= fun w_limit ->
  let rec box_render (acc:Ui.t) (i:int) l : Ui.t =
    match l with
    | [] -> acc
    | ui0 :: tl ->
      let w0 = (Ui.layout_spec ui0).Ui.w in
      if i + w0 >= w_limit then (
        (* newline starting with ui0 *)
        Ui.join_y acc (box_render ui0 w0 tl)
      ) else (
        (* same line *)
        box_render (Ui.join_x acc ui0) (i+w0) tl
      )
  in
  box_render Ui.empty 0 l


(** Prints the summary, but calls [f()] to compute a sub-widget
    when clicked on. Useful for displaying deep trees. *)
let unfoldable ?(folded_by_default=true) summary (f: unit -> Ui.t Lwd.t) : Ui.t Lwd.t =
  let open Lwd.Infix in
  let opened = Lwd.var (not folded_by_default) in
  let fold_content =
    Lwd.get opened >>= function
    | true ->
      (* call [f] and pad a bit *)
      f() |> Lwd.map ~f:(Ui.join_x (string " "))
    | false -> empty_lwd
  in
  (* pad summary with a "> " when it's opened *)
  let summary =
    Lwd.get opened >>= fun op ->
    summary >|= fun s ->
    Ui.hcat [string ~attr:attr_clickable (if op then "v" else ">"); string " "; s]
  in
  let cursor ~x:_ ~y:_ = function
     | `Left when Lwd.peek opened -> Lwd.set opened false; `Handled
     | `Left -> Lwd.set opened true; `Handled
     | _ -> `Unhandled
  in
  let mouse = Lwd.map ~f:(fun m -> Ui.mouse_area cursor m) summary in
  Lwd.map2 mouse fold_content
    ~f:(fun summary fold ->
      (* TODO: make this configurable/optional *)
      (* newline if it's too big to fit on one line nicely *)
      let spec_sum = Ui.layout_spec summary in
      let spec_fold = Ui.layout_spec fold in
      (* TODO: somehow, probe for available width here? *)
      let too_big =
        spec_fold.Ui.h > 1 ||
        (spec_fold.Ui.h>0 && spec_sum.Ui.w + spec_fold.Ui.w > 60)
      in
      if too_big
      then Ui.join_y summary (Ui.join_x (string " ") fold)
      else Ui.join_x summary fold)

let hbox l = Lwd_utils.pack Ui.pack_x l
let vbox l = Lwd_utils.pack Ui.pack_y l
let zbox l = Lwd_utils.pack Ui.pack_z l

let vlist ?(bullet="- ") (l: Ui.t Lwd.t list) : Ui.t Lwd.t =
  l
  |> List.map (fun ui -> Lwd.map ~f:(Ui.join_x (string bullet)) ui)
  |> Lwd_utils.pack Ui.pack_y

(** A list of items with a dynamic filter on the items *)
let vlist_with
    ?(bullet="- ")
    ?(filter=Lwd.return (fun _ -> true))
    (f:'a -> Ui.t Lwd.t)
    (l:'a list Lwd.t) : Ui.t Lwd.t =
  let open Lwd.Infix in
  let rec filter_map_ acc f l =
    match l with
    | [] -> List.rev acc
    | x::l' ->
      let acc' = match f x with | None -> acc | Some y -> y::acc in
      filter_map_ acc' f l'
  in
  let l =
    l >|= List.map (fun x -> x, Lwd.map ~f:(Ui.join_x (string bullet)) @@ f x)
  in
  let l_filter : _ list Lwd.t =
    filter >>= fun filter ->
    l >|=
    filter_map_ []
      (fun (x,ui) -> if filter x then Some ui else None)
  in
  l_filter >>= Lwd_utils.pack Ui.pack_y

let rec iterate n f x =
  if n=0 then x else iterate (n-1) f (f x)

(** A grid layout, with alignment in all rows/columns.
    @param max_h maximum height of a cell
    @param max_w maximum width of a cell
    @param bg attribute for controlling background style
    @param h_space horizontal space between each cell in a row
    @param v_space vertical space between each row
    @param pad used to control padding of cells
    @param crop used to control cropping of cells
    TODO: control padding/alignment, vertically and horizontally
    TODO: control align left/right in cells
    TODO: horizontal rule below headers
    TODO: headers *)
let grid
    ?max_h ?max_w
    ?pad ?crop ?bg
    ?(h_space=0)
    ?(v_space=0)
    ?(headers:Ui.t Lwd.t list option)
    (rows: Ui.t Lwd.t list list) : Ui.t Lwd.t =
  let rows = match headers with
    | None -> rows
    | Some r -> r :: rows
  in
  (* build a [ui list list Lwd.t] *)
  begin
    Lwd_utils.map_l (fun r -> Lwd_utils.flatten_l r) rows
  end >>= fun (rows:Ui.t list list) ->
  (* determine width of each column and height of each row *)
  let n_cols = List.fold_left (fun n r -> maxi n (List.length r)) 0 rows in
  let col_widths = Array.make n_cols 1 in
  List.iter
    (fun row ->
       List.iteri
         (fun col_j cell ->
           let w = (Ui.layout_spec cell).Ui.w in
           col_widths.(col_j) <- maxi col_widths.(col_j) w)
         row)
    rows;
  begin match max_w with
    | None -> ()
    | Some max_w ->
      (* limit width *)
      Array.iteri (fun i x -> col_widths.(i) <- mini x max_w) col_widths
  end;
  (* now render, with some padding *)
  let pack_pad_x =
    if h_space<=0 then (Ui.empty, Ui.join_x)
    else (Ui.empty, (fun x y -> Ui.hcat [x; Ui.space h_space 0; y]))
  and pack_pad_y =
    if v_space =0 then (Ui.empty, Ui.join_y)
    else (Ui.empty, (fun x y -> Ui.vcat [x; Ui.space v_space 0; y]))
  in
  let rows =
    List.map
      (fun row ->
         let row_h =
           List.fold_left (fun n c -> maxi n (Ui.layout_spec c).Ui.h) 0 row
         in
         let row_h = match max_h with
           | None -> row_h
           | Some max_h -> mini row_h max_h
         in
         let row =
           List.mapi
             (fun i c ->
                Ui.resize ~w:col_widths.(i) ~h:row_h ?crop ?pad ?bg c)
             row
         in
         Lwd_utils.reduce pack_pad_x row)
      rows
  in
  (* TODO: mouse and keyboard handling *)
  let ui = Lwd_utils.reduce pack_pad_y rows in
  Lwd.return ui

(** Turn the given [ui] into a clickable button, calls [f] when clicked. *)
let button_of ui f =
  Ui.mouse_area (fun ~x:_ ~y:_ _ -> f(); `Handled) ui

(** A clickable button that calls [f] when clicked, labelled with a string. *)
let button ?(attr=attr_clickable) s f = button_of (string ~attr s) f

(* file explorer for selecting a file *)
let file_select
    ?(abs=false)
    ?filter
    ~(on_select:string -> unit) () : Ui.t Lwd.t =
  let rec aux ~fold path =
    try
      let p_rel = if path = "" then "." else path in
      if Sys.is_directory p_rel then (
        let ui() =
          let arr = Sys.readdir p_rel in
          let l = Array.to_list arr |> List.map (Filename.concat path) in
          (* apply potential filter *)
          let l = match filter with None -> l | Some f -> List.filter f l in
          let l = Lwd.return @@ List.sort String.compare l in
          vlist_with ~bullet:"" (aux ~fold:true) l
        in
        if fold then (
          unfoldable ~folded_by_default:true
            (Lwd.return @@ string @@ path ^ "/") ui
        ) else ui ()
      ) else (
        Lwd.return @@
        button ~attr:A.(st underline) path (fun () -> on_select path)
      )
    with e ->
      Lwd.return @@ Ui.vcat [
        printf ~attr:A.(bg red) "cannot list directory %s" path;
        string @@ Printexc.to_string e;
      ]
  in
  let start = if abs then Sys.getcwd () else "" in
  aux ~fold:false start

let toggle, toggle' =
  let toggle_ st (lbl:string Lwd.t) (f:bool -> unit) : Ui.t Lwd.t =
    let mk_but st_v lbl_v =
      let lbl = Ui.hcat [
          printf "[%s|" lbl_v;
          string ~attr:attr_clickable (if st_v then "✔" else "×");
          string "]";
        ] in
      button_of lbl (fun () ->
          let new_st = not st_v in
          Lwd.set st new_st; f new_st)
    in
    Lwd.map2 ~f:mk_but (Lwd.get st) lbl
  in
  (* Similar to {!toggle}, except it directly reflects the state of a variable. *)
  let toggle' (lbl:string Lwd.t) (v:bool Lwd.var) : Ui.t Lwd.t =
    toggle_ v lbl (Lwd.set v)
  (* a toggle, with a true/false state *)
  and toggle ?(init=false) (lbl:string Lwd.t) (f:bool -> unit) : Ui.t Lwd.t =
    let st = Lwd.var init in
    toggle_ st lbl f
  in
  toggle, toggle'


type scrollbox_state = { w: int; h: int; x: int; y: int; }

let adjust_offset visible total off =
  let off = if off + visible > total then total - visible else off in
  let off = if off < 0 then 0 else off in
  off

let decr_if x cond = if cond then x - 1 else x

let scrollbar_bg = Notty.A.gray 4
let scrollbar_fg = Notty.A.gray 7
let scrollbar_click_step = 3 (* Clicking scrolls one third of the screen *)
let scrollbar_wheel_step = 8 (* Wheel event scrolls 1/8th of the screen *)

let hscrollbar visible total offset ~set =
  let prefix = offset * visible / total in
  let suffix = (total - offset - visible) * visible / total in
  let handle = visible - prefix - suffix in
  let render size color = Ui.atom Notty.(I.char (A.bg color) ' ' size 1) in
  let mouse_handler ~x ~y:_ = function
    | `Left ->
      if x < prefix then
        (set (offset - maxi 1 (visible / scrollbar_click_step)); `Handled)
      else if x > prefix + handle then
        (set (offset + maxi 1 (visible / scrollbar_click_step)); `Handled)
      else `Grab (
          (fun ~x:x' ~y:_ -> set (offset + (x' - x) * total / visible)),
          (fun ~x:_ ~y:_ -> ())
        )
    | `Scroll dir ->
      let dir = match dir with `Down -> +1 | `Up -> -1 in
      set (offset + dir * (maxi 1 (visible / scrollbar_wheel_step)));
      `Handled
    | _ -> `Unhandled
  in
  let (++) = Ui.join_x in
  Ui.mouse_area mouse_handler (
    render prefix scrollbar_bg ++
    render handle scrollbar_fg ++
    render suffix scrollbar_bg
  )

let vscrollbar visible total offset ~set =
  let prefix = offset * visible / total in
  let suffix = (total - offset - visible) * visible / total in
  let handle = visible - prefix - suffix in
  let render size color = Ui.atom Notty.(I.char (A.bg color) ' ' 1 size) in
  let mouse_handler ~x:_ ~y = function
    | `Left ->
      if y < prefix then
        (set (offset - maxi 1 (visible / scrollbar_click_step)); `Handled)
      else if y > prefix + handle then
        (set (offset + maxi 1 (visible / scrollbar_click_step)); `Handled)
      else `Grab (
          (fun ~x:_ ~y:y' -> set (offset + (y' - y) * total / visible)),
          (fun ~x:_ ~y:_ -> ())
        )
    | `Scroll dir ->
      let dir = match dir with `Down -> +1 | `Up -> -1 in
      set (offset + dir * (maxi 1 (visible / scrollbar_wheel_step)));
      `Handled
    | _ -> `Unhandled
  in
  let (++) = Ui.join_y in
  Ui.mouse_area mouse_handler (
    render prefix scrollbar_bg ++
    render handle scrollbar_fg ++
    render suffix scrollbar_bg
  )

let scrollbox t =
  (* Keep track of scroll state *)
  let state_var = Lwd.var {w = 0; h = 0; x = 0; y = 0} in
  (* Keep track of size available for display *)
  let update_size ~w ~h =
    let state = Lwd.peek state_var in
    if state.w <> w || state.h <> h then Lwd.set state_var {state with w; h}
  in
  let measure_size body =
    Ui.size_sensor update_size (Ui.resize ~w:0 ~h:0 ~sw:1 ~sh:1 body)
  in
  (* Given body and state, composite scroll bars *)
  let compose_bars body state =
    let (bw, bh) = Ui.layout_width body, Ui.layout_height body in
    (* Logic to determine which scroll bar should be visible *)
    let hvisible = state.w < bw and vvisible = state.h < bh in
    let hvisible = hvisible || (vvisible && state.w = bw) in
    let vvisible = vvisible || (hvisible && state.h = bh) in
    (* Compute size and offsets based on visibility *)
    let state_w = decr_if state.w vvisible in
    let state_h = decr_if state.h hvisible in
    let state_x = adjust_offset state_w bw state.x in
    let state_y = adjust_offset state_h bh state.y in
    (* Composite visible scroll bars *)
    let crop b =
      Ui.resize ~sw:1 ~sh:1 ~w:0 ~h:0
        (Ui.shift_area state_x state_y b)
    in
    let set_vscroll y =
      let state = Lwd.peek state_var in
      if state.y <> y then Lwd.set state_var {state with y}
    in
    let set_hscroll x =
      let state = Lwd.peek state_var in
      if state.x <> x then Lwd.set state_var {state with x}
    in
    let (<->) = Ui.join_y and (<|>) = Ui.join_x in
    match hvisible, vvisible with
    | false , false -> body
    | false , true  ->
      crop body <|> vscrollbar state_h bh state_y ~set:set_vscroll
    | true  , false ->
      crop body <-> hscrollbar state_w bw state_x ~set:set_hscroll
    | true  , true  ->
      (crop body <|> vscrollbar state_h bh state_y ~set:set_vscroll)
      <->
      (hscrollbar state_w bw state_x ~set:set_hscroll <|> Ui.space 1 1)
  in
  (* Render final box *)
  Lwd.map2 t (Lwd.get state_var)
    ~f:(fun ui size -> measure_size (compose_bars ui size))
