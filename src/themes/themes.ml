type t = Default | Vanier | None

let to_string = function
  | Default -> "default"
  | Vanier -> "vanier"
  | None -> "none"

let of_string = function
  | "default" -> Some Default
  | "vanier" -> Some Vanier
  | "none" -> Some None
  | _ -> None

let content = function
  | Default -> [%blob "default.css"]
  | Vanier -> [%blob "vanier.css"]
  | None -> ""
