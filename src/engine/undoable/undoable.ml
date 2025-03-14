include Monad
module Browser = Browser_

module List = struct
  open Syntax

  let iter f l =
    List.fold_left
      (fun acc x ->
        let> () = acc in
        f x)
      (return ()) l
end
