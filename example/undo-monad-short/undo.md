# The Undo Monad

![](undomonad.draw){#undomonaddraw draw}

{draw=undomonaddraw}


{up style="margin-top:1000px" pause}
We want to encode **revertible computations with side effects**.

```ocaml
type 'a t = {
  value : 'a;
  undo : unit -> unit;
}
```

{draw=undomonaddraw}

{draw=undomonaddraw}

{pause}
```ocaml
let return undo value = {undo; value}
```

{pause #binddef}
```ocaml
let bind computation1 f =
  let computation2 = f computation1.value in
  let value = computation2.value in
  let undo =
    computation2.undo ();
    computation1.undo ()
  in
  {undo; value}
```

{draw=undomonaddraw}

{up=binddef pause}
```ocaml
let next () =
  let x = querySelector "[pause]" in
  let* () = set_style x "display:none" in
  let y = document.querySelectorAll(".action") in
  Undo_monad.List.map (fun e -> remove_class e "action") y

let result = next ()

computation.undo ()
```

{pause down}
```ocaml
let remove_class e c =
  let had_class = get_class e c in
  let undo () = set_class e c had_class in
  {
    value = remove_class e c;
    undo = undo
  }
```

{draw=undomonaddraw}

