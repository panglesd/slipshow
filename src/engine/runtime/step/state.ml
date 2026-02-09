type transition = {
  from : int;
  to_ : int;
  mode : Fast.mode;
  mutable next : transition option;
}

type t = At of int | Transition of transition

let step = ref (At 0)
let get_step () = !step

let counter =
  Brr.El.find_first_by_selector (Jstr.v "#slipshow-counter") |> Option.get

let set_counter s = Brr.El.set_children counter [ Brr.El.txt' s ]

let to_string = function
  | At n -> string_of_int n
  | Transition { from; to_; _ } -> string_of_int from ^ "→" ^ string_of_int to_

let set_step s =
  set_counter (to_string s);
  step := s
