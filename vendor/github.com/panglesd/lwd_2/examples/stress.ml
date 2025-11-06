open Nottui
open Nottui_widgets

(* App-specific widgets *)

let strict_table () =
  let columns = Lwd_table.make () in
  let cells =
    Array.init 100 (fun _ ->
        let rows = Lwd_table.make () in
        Lwd_table.append' columns rows;
        Array.init 100 (fun _ -> Lwd_table.append rows ~set:0))
  in
  let render_cell _ v = string (string_of_int v) in
  let render_column _ rows = Lwd_table.map_reduce render_cell Ui.pack_y rows in
  let table =
    Lwd_table.map_reduce render_column
      (Lwd_utils.lift_monoid Ui.pack_x)
      columns
  in
  (cells, Lwd.join table |> scroll_area)

(* Entry point *)

(*let () = Statmemprof_emacs.start 1E-4 30 5*)

let walk cell =
  let v = match Lwd_table.get cell with None -> 0 | Some x -> x in
  Lwd_table.set cell (v + Random.int 20 - 10)

let () =
  let cells, table = strict_table () in
  let term = Notty_unix.Term.create () in
  let renderer = Renderer.make () in
  let root = Lwd.observe table in
  for _ = 0 to 99 do
    Nottui_unix.step ~timeout:0.0 ~process_event:true ~renderer term root;
    Array.iter (Array.iter walk) cells
  done;
  Lwd.quick_release root;
  Notty_unix.Term.release term
