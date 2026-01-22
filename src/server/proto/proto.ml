type t = Update of string | GoForward | GoBackward

let to_string (v : t) = Marshal.to_string v []
let of_string s : t = (Marshal.from_string s 0 : t)
