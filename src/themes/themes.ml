type t = Default | Vanier | NoTheme

let all = [ Default; Vanier; NoTheme ]

let to_string = function
  | Default -> "default"
  | Vanier -> "vanier"
  | NoTheme -> "none"

let description = function
  | Default -> "The default theme, inspired from Beamer's Warsaw theme."
  | Vanier -> "Another Warsaw inspired theme."
  | NoTheme -> "Include no theme."

let of_string = function
  | "default" -> Some Default
  | "vanier" -> Some Vanier
  | "none" -> Some NoTheme
  | _ -> None

let content ?(lite = true) = function
  | Default when lite ->
      [%blob "font-embedding-lite.css"] ^ [%blob "default.css"]
  | Default -> [%blob "font-embedding.css"] ^ [%blob "default.css"]
  | Vanier when lite -> [%blob "font-embedding-lite.css"] ^ [%blob "vanier.css"]
  | Vanier -> [%blob "font-embedding.css"] ^ [%blob "vanier.css"]
  | NoTheme -> ""
