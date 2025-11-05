(*
    document.body.style.cursor = "auto";
    let timeOutIds = [];
    document.body.addEventListener("mousemove", (ev) => {
	timeOutIds.forEach((id) => { clearTimeout(id); });
	document.body.style.cursor = "auto";
	timeOutIds.push(setTimeout(() => { document.body.style.cursor = "none";}, 5000));
    });
 *)
let body = Brr.Document.body Brr.G.document

let show_cursor () =
  Brr.El.set_inline_style Brr.El.Style.cursor (Jstr.v "auto") body

let hide_cursor () =
  Brr.El.set_inline_style Brr.El.Style.cursor (Jstr.v "none") body

let setup () =
  show_cursor ();
  let timeout_id = ref None in
  let _unlisten =
    Brr.Ev.listen Brr.Ev.pointermove
      (fun _ ->
        (match !timeout_id with None -> () | Some id -> Brr.G.stop_timer id);
        show_cursor ();
        let id = Brr.G.set_timeout ~ms:5000 (fun _ -> hide_cursor ()) in
        timeout_id := Some id)
      (Brr.El.as_target body)
  in
  ()
