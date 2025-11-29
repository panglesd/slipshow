let date = Jv.get Jv.global "Date"
let now () = Jv.call date "now" [||] |> Jv.to_int

let soi i =
  if i = 0 then "00"
  else if i < 10 then "0" ^ string_of_int i
  else string_of_int i

let string_of_t ms =
  let t = ms / 1000 in
  let s = t mod 60 in
  let m = t / 60 in
  let h = m / 60 in
  let m = m mod 60 in
  soi h ^ ":" ^ soi m ^ ":" ^ soi s

let setup_timer el =
  let timer_mode = ref (`Since (now ())) in
  let timer = Brr.El.span [] in
  let restart =
    Brr.El.input
      ~at:[ Brr.At.type' (Jstr.v "button"); Brr.At.value (Jstr.v "Restart") ]
      ()
  in
  let pause =
    Brr.El.input
      ~at:
        [
          Brr.At.type' (Jstr.v "button");
          Brr.At.value (Jstr.v "Play/Pause");
          Brr.At.style (Jstr.v "margin-left: 20px");
        ]
      ()
  in
  let current_time = ref "" in
  let _ =
    Brr.Ev.listen Brr.Ev.click
      (fun _ ->
        match !timer_mode with
        | `Since _ -> timer_mode := `Since (now ())
        | `Paused_at _ -> timer_mode := `Paused_at 0)
      (Brr.El.as_target restart)
  in
  let _ =
    Brr.Ev.listen Brr.Ev.click
      (fun _ ->
        match !timer_mode with
        | `Since n -> timer_mode := `Paused_at (now () - n)
        | `Paused_at n -> timer_mode := `Since (now () - n))
      (Brr.El.as_target pause)
  in
  Brr.El.set_children el [ timer; pause; restart ];
  Brr.G.set_interval ~ms:100 (fun () ->
      let v =
        match !timer_mode with `Since n -> now () - n | `Paused_at n -> n
      in
      let new_current_time = "⏱️ " ^ string_of_t v in
      if not (String.equal !current_time new_current_time) then (
        Brr.El.set_children timer [ Brr.El.txt' new_current_time ];
        current_time := new_current_time))

let clock el =
  let write_date () =
    let now = Jv.new' date [||] in
    let hours = Jv.call now "getHours" [||] |> Jv.to_int in
    let minutes = Jv.call now "getMinutes" [||] |> Jv.to_int in
    Brr.El.set_children el
      [ Brr.El.txt' ("⏰ " ^ soi hours ^ ":" ^ soi minutes) ]
  in
  write_date ();
  Brr.G.set_interval ~ms:20000 write_date
