# Monads

{.definition #monadef}
Monads are a design-pattern to represent computations as expressions.

{pause style="margin-bottom:10px"}
But first, let's see where they come from.

{style=height:100px; .flex .just .bottom-border #horiline}
> **Statement-based**
>
> **Expression-based**

{style=height:100px;margin-top:-40px .flex .just .anchor-center}
> {.arrow-left}
>
> {.arrow-middle}
>
> {.arrow-right}


{.flex children:slip}
-----
# Assembler

{.flex .anchor-center style="gap:30px"}
---

```x86asm
loop:
    cmp  eax, 1      ; Check if number is 1
    je   done        ; If yes, stop
    test al, 1       ; Check if odd
    jz   even        ; If 0, jump to even case
    imul eax, 3      ; n = n * 3
    inc  eax         ; n = n + 1
    jmp  loop        ; Restart loop

even:
    shr  eax, 1      ; Divide by 2
    jmp  loop        ; Restart loop

done:
```

> - AST is a list of instructions {pause}
>
> - **No expression:** `3n+1` cannot be easily expressed. {pause}
>
> - Order of execution is well defined, by step. {pause}
>
> - Next step depend on the previous one (eg in `je`).

----
# Imperative languages

![Statement vs expressions](stmt-vs-expr.draw){#stmt-vs-expr}

{.flex .anchor-center style="gap:30px"}
---

```
while(x != 1) {
  if (x mod 2 === 0)           
    x = x / 2
  else
    x = 3 * x + 1
}
```

- Statements{.red} versus expressions{.green}. {pause draw=stmt-vs-expr}

    - Statements{.red} as lists (mostly). **Explicit execution order.** {pause draw=stmt-vs-expr} {draw=stmt-vs-expr}

    - Expressions{.green} as trees. {pause} **Unclear evaluation order.** {pause}

- Fortunately, expression don't have side-effects. {pause} **Do they???**

{.flex .anchor-center style="gap:30px" pause draw=stmt-vs-expr}
---

{draw=stmt-vs-expr}
```
function with_log(x) {
  console.log(x);
  return x;
}

x1 = with_log(true) || with_log(false);
```
{pause}
```
function or (x,y) {
  return x || y;
}

x2 = or (with_log(true), with_log(false));

```

{draw=stmt-vs-expr}

----
# Functional languages

{.flex .anchor-center style="gap:30px"}
---

```
let rec syracuse =
  if x = 1 then ()
  else syracuse
         (if x mod 2 then x / 2       
          else 3 * x + 1)
```

- Only expressions{.green}!

- What about side-effects? Do we have the same problem?

{pause}
---

{.block #hask}
- **OCaml**: we define the evaluation order on some AST nodes. Leave it
  undefined in others. {pause}

- **Haskell**: we only have pure expressions. No more evaluation order problem.

![Greeting](greet.draw){draw}

{up=hask}

{.block title="Idea" style="margin-top:275px"}
>
> 1. Have a way to *represent* computations as pure values.
>
> 2. Have a DSL (mini language) to manipulate computations.
>
> 3. The entry point (`main`) returns such a computation, which is executed.

![Haskell](haskell.draw){#hkd}

{draw=hkd}

{draw=hkd}

{draw=hkd}

-----

{.theorem #conc1 style="margin-top:80px" down=conc1}
- Functional programming has a **trick** to have **side-effects** in a **side-effect free language** {pause}

- The same trick can represent:
  - **Exceptions** in a language **without exceptions**

  - **Asynchronous** programming in a **synchronous language**, ... {pause}

- All those "extensions" follow the same pattern: [**the "Monad" design pattern**]{.red}.

<style>
.theorem:before {
  content: "Recap";
}
.theorem {
  font-style: normal;
}
</style>

{pause up}
## Monads: a design pattern to represent computations

4 simple ingredients:

![Bobnads](bobnads.draw){#bobnads draw}

{.flex .just children:pause-block}
----
{pause-block}
> ### A type
>
> {pause}
>
> ```ocaml
> type 'a computation
> ```

### Running computations

{#also-run}
```ocaml
val run :
  'a computation ->
  'a
```

---
### Creating atomic computations

{pause}

```ocaml
val read_line :
  unit -> string computation

val print_line :
  string -> unit computation
...
```

{pause}

```ocaml
val return : 'a -> 'a computation
```

---
### Chaining computations

{pause}

{.pseudo-code}
```text
x ← comp1 ;
comp2
```

{draw=bobnads}

{pause}

```ocaml
val bind :
  'a computation ->
  ('a -> 'b computation) ->
  'b computation
```

{draw=bobnads}

{draw=bobnads}

{draw=bobnads}

{draw=bobnads}

{draw=bobnads}


---

{pause=also-run}

{draw=bobnads}

----

{.center pause down=exam1}
## Example:

{.flex style=justify-content:space-around #exam1}
---
> ### Computation to represent
> {.pseudo-code}
> ```
> s <- read_line();
> print_line (s ^ s)          
> ```

> ### Representation in the monad
> ```ocaml
> bind
>   (read_line ())
>   (fun s ->
>     print_line (s ^ s))     
> ```
> {draw=bobnads}



{.flex style=justify-content:space-around down  #exam12}
---
> {.pseudo-code}
> ```
> s1 <- read_line();
> s2 <- read_line();
> print_line (s1 ^ s2)        
> ```

> {pause}
> ```ocaml
> bind
>   (read_line ())
>   (fun s1 ->
>     bind
>      (readline ())
>      (fun s2 ->
>       print_line (s1 ^ s2)))
> ```


---

{pause up=exam12}
## Syntactic support for monads

{.flex style=justify-content:space-around}
---
> ```ocaml
> bind x (fun s -> body)       
> ```

> {pause}
> ```ocaml
> let* s = x in              
> body
> ```
> {draw=bobnads}



---
{pause down}
```ocaml
let (let*) = bind

let comp : unit computation =
  let* s1 = read_line () in
  let* s2 = read_line () in
  print_line (s1 ^ s2)
```

