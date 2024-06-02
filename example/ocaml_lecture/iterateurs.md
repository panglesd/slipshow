# Itérateurs

```ocaml
val mystere : 'a list -> ('a -> 'b) -> 'b list
```

À partir du type de `mystere`, tentez de deviner ce que fait cette fonction.

{pause}

{#traverseur}
### Les itérateurs : traverser un type de donnée

Il existe plusieurs types d'itérateurs :

- Le `map`:
```ocaml
val map : 'a list -> ('a -> 'b) -> 'b list
```
{pause}
- L'`iter`:
```ocaml
val iter : 'a list -> ('a -> unit) -> unit
```
{pause up=traverseur}
- Le `fold`:
{#folds}
```ocaml
val fold_left : 'a list -> ('acc -> 'a -> 'acc) -> 'acc -> 'acc
val fold_right : 'a list -> ('a -> 'acc -> 'acc) -> 'acc -> 'acc
```

...

{pause}
## Faites les exercices

{pause up}
## Récursion terminale

{.definition}
Lorsqu'une fonction termine par un (unique) appel récursif, on dit qu'elle est **récursive terminale**.

{.example pause}
>
>
> ```ocaml
> let rec length l = match l with 
>   | [] -> 0
>   | _ :: q ->
>     let lq = length q in
>     lq + 1
> ```
> { pause #no-rec-term}
> ```ocaml
> let rec length l = match l with 
>   | [] -> 0
>   | _ :: q -> 1 + (length q)
> ```
> { pause}
> ```ocaml
> let rec length acc l = match l with 
>   | [] -> acc
>   | _ :: q -> length (acc + 1)
> ```

{pause up=no-rec-term}
Une fonction récursive terminale ne fera pas de `Stack_overflow`. Comparons l'execution dans le cas non-récursif terminal:

```
   length [1; 2; 3]
=> 1 + length [2; 3]
=> 1 + (1 + length [3])
=> 1 + (1 + (1 + length []))
=> 1 + (1 + (1 + 0))
=> 1 + (1 + 1)
=> 1 + 2
=> 3
```

{pause down=rec-term-exec}
et dans le cas récursif terminal:

{#rec-term-exec}
```
   length 0 [1; 2; 3]
=> length 1 [2; 3]
=> length 2 [3]
=> length 3 []
=> 3
```

{pause down}
## Refaire les exercices en mode "récursif terminale"
