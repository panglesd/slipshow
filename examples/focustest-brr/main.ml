open Brr
open Brr_lwd

let ui =
  let values = Lwd_table.make () in
  let items = Lwd.var Lwd_seq.empty in
  let shuffle () =
    let all = Lwd_seq.to_array (Lwd.peek items) in
    for i = Array.length all - 1 downto 1 do
      let i' = Random.int (i + 1) in
      let x = all.(i) in
      let x' = all.(i') in
      all.(i') <- x;
      all.(i) <- x';
    done;
    Lwd.set items (Lwd_seq.of_array all)
  in
  let edit _ =
    let row = Lwd_table.append values in
    Lwd.map (Elwd.input ()) ~f:(fun el ->
        ignore (
          Ev.listen Ev.input (fun _ ->
            let txt = Jstr.to_string (El.prop El.Prop.value el) in
            Console.log ["shuffle"; txt];
            Lwd_table.set row txt;
            shuffle ()
          ) (El.as_target el)
        );
        el
      )
  in
  Lwd.set items (Lwd_seq.of_array (Array.init 10 edit));
  let values =
    Lwd_table.map_reduce
      (fun _row txt -> Lwd_seq.element (txt ^ "\n"))
      (Lwd_seq.monoid)
      values
    |> Lwd_seq.sort_uniq String.compare
  in
  Elwd.div [
    `P (El.txt' "In this test, typing in one of the input field should \
                 shuffle them. The test succeeds if focus and selections are \
                 preserved after shuffling.");
    `P (El.br ());
    `S (Lwd_seq.lift (Lwd.get items));
    `S (Lwd_seq.map El.txt' values);
  ]

let () =
  let ui = Lwd.observe ui in
  let on_invalidate _ =
    Console.(log [str "on invalidate"]);
    let _ : int =
      G.request_animation_frame @@ fun _ ->
      let _ui = Lwd.quick_sample ui in
      (*El.set_children (Document.body G.document) [ui]*)
      ()
    in
    ()
  in
  let on_load _ =
    Console.(log [str "onload"]);
    El.append_children (Document.body G.document) [Lwd.quick_sample ui];
    Lwd.set_on_invalidate ui on_invalidate
  in
  ignore (Ev.listen Ev.dom_content_loaded on_load (Window.as_target G.window));
  ()
