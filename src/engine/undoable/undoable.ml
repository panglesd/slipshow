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

module Stack = struct
  let push x s =
    let undo () = Fut.return @@ ignore @@ Stack.pop s in
    return ~undo (Stack.push x s)

  let pop_opt stack =
    let value = Stack.pop_opt stack in
    let undo () =
      Fut.return @@ Option.iter (fun v -> Stack.push v stack) value
    in
    return ~undo value
end
