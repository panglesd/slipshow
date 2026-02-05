type hurry_bomb = {
  wait : unit Fut.t;
  has_detonated : bool ref;
  detonate : unit -> unit;
}

let has_detonated h = !(h.has_detonated)
let detonate h = h.detonate ()
let wait h = h.wait

let create () =
  let has_detonated = ref false in
  let wait, detonate = Fut.create () in
  let wait = Fut.map (fun () -> has_detonated := true) wait in
  { wait; has_detonated; detonate }

type mode = Normal of hurry_bomb | Counting_for_toc | Fast | Slow

let normal () = Normal (create ())
let counting_for_toc = Counting_for_toc
let fast = Fast
let slow = Slow
let is_fast = function Normal h -> has_detonated h | Slow -> false | _ -> true
