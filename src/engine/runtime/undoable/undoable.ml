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

  let rec filter_map f = function
    | [] -> return []
    | x :: l -> (
        let> res = f x in
        match res with
        | None -> filter_map f l
        | Some v ->
            let> res = filter_map f l in
            return @@ (v :: res))
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

  let peek stack =
    match Stack.pop_opt stack with
    | None -> None
    | Some x as s ->
        Stack.push x stack;
        s
end

module Option = struct
  let iter f = function None -> return () | Some x -> f x
end

module Ref = struct
  let set x v =
    let old_v = !x in
    let undo () = Fut.return @@ (x := old_v) in
    return ~undo (x := v)
end
