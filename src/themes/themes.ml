type t = Default | Vanier | None

let all = [ Default; Vanier; None ]

let to_string = function
  | Default -> "default"
  | Vanier -> "vanier"
  | None -> "none"

let description = function
  | Default -> "The default theme, inspired from Beamer's Warsaw theme."
  | Vanier -> "Another Warsaw inspired theme."
  | None -> "Include no theme."

let of_string = function
  | "default" -> Some Default
  | "vanier" -> Some Vanier
  | "none" -> Some None
  | _ -> None

let content = function
  | Default -> [%blob "default.css"]
  | Vanier -> [%blob "vanier.css"]
  | None -> ""
