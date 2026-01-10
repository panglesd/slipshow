# The SECRET of adding features in 3 SIMPLE STEPS

{.block #step1dis}
{pause}
-----
# Step 1: Discipline

{style="display: flex; justify-content: space-around"}
> {style="text-align: center"}
> ### Morning
>
> {.unrevealed reveal}
> > 5:00 – Waking up, go for a footing,
> >
> > 6:00 – Yoga Sun salutations and stretching,
> >
> > 6:30 – Cold shower,
> >
> > 6:45 – eat vegan breakfast,
> >
> > 7:00 – First beer,
> >
> > 8:00 – Read blog posts on how to be efficient.
>
> ---
>
> {style="text-align: center"}
> ### Afternoon
>
> {.unrevealed reveal}
> > 1:00 – Fasting window (Yogi tea)
> >
> > 1:30 – Nutella spread
> >
> > 2:30 – Look at cat videos on youtube
> >
> > 7:30 – Get Things Done
> >
> > 8:00 – Look back on work done
> >
> > 11:59 – Last beer

<!-- Pay to unlock. I'll make it free but you can buy my other book, How to
achieve transcendence in three simple steps -->

{.block #step2org}
{pause up}
-----

# Step 2: Organization

{include .notshowing #theroles src=roles.md}



{exec}
``` slip-script
slip.setClass(document.querySelector("#theroles"), "notshowing", false);
```



{.block}
{#ocaml-section pause up}
-----

# Step 3: OCaml

Last but not least!

{style=display:flex}
----

{slip pause=oneofone}
---
# Ecosystem

{#oneofone}
OCaml is even more full-featured than Slipshow

<style>
p code {
  background-color:#f3f3f3;
  padding:10px;
}
</style>

- `cmdliner` writes a help page for me,

- `js_of_ocaml` writes Javascript for me,

- `cmarkit` parses markdown for me,

- `perfect-freehand` generates strokes for me,

  {#thatsajs pause}
  - That's a JS library!

- `patricoferris` binds `code-mirror` for me! {pause}

- `lambdasoup` write "`jq` for html" for me!

  ```ocaml
  open Soup

  let () =
    let content = read_file Sys.argv.(1) |> parse in
    let iframe = content $ "#slipshow__internal_iframe" in
    let a = R.attribute "srcdoc" iframe in
    print_endline a
  ```

{up=ocaml-section}
---

{slip pause=featurelistoca}
---
# Language

{#featurelistoca style="display: flex; flex-wrap: wrap; justify-content: space-evenly;" children:.block children:style="margin: 10px"}
> ✅️ Functors
>
> ✅️ First class modules
>
> ✅️ GADT
>
> {#monadic-binds}
> ✅️ Monadic binds
>
> ✅️ Extensible variants
>
> ✅️ Polymorphic datatypes
>
> ❌ Objects
>
> ❌ Effects
>
> ❌ Parallelism

<style>.ssellected { background-color: lightgreen } </style>

{exec pause}
```slip-script
slip.setClass(document.querySelector("#monadic-binds"), "ssellected", true)
```

{#tum}
## Monadic binds: The Undo Monad

<x-ocaml>
type 'a with_undo = { v : 'a; undo : unit -> unit }
</x-ocaml>

A value, and a way to "undo" its side effects.

<script async
  src="https://cdn.jsdelivr.net/gh/art-w/x-ocaml.js@6/x-ocaml.js"
  src-worker="https://cdn.jsdelivr.net/gh/art-w/x-ocaml.js@6/x-ocaml.worker+effects.js"
  integrity="sha256-3ITn2LRgP/8Rz6oqP5ZQTysesNaSi6/iEdbDvBfyCSE="
  crossorigin="anonymous"
  x-ocamlformat="disable=true"
></script>

{.unstatic}
<x-ocaml>
let set x v =
   Format.printf "Setting value from %d to %d\n%!" !x v;
   x := v
let (:=) x v = set x v
</x-ocaml>

{pause #setu up=tum}
<x-ocaml>
let set_u x n =
  let undo =
    let old_x = !x in
    fun () -> x := old_x
  in
  let v = x := n in
  { v; undo }
</x-ocaml>

{#hiding-block}

{unstatic=hiding-block}

<style>
#hiding-block {
    height: 100px;
    background-color: grey;
    position: absolute;
    width: 37%;
    top: 840px;
    left: 271px;
}
</style>


{pause up=setu}
A way to combine undoable values

{#bindmon}
<x-ocaml>
let bind (x : 'a with_undo) (f : 'a -> 'b with_undo) : 'b with_undo =
  let y = f x.v in
  let undo () =
    y.undo ();
    x.undo ()
  in
  { v = y.v; undo }
</x-ocaml>

{#hiding-block2}

{unstatic=hiding-block2}

<style>
#hiding-block2 {
    height: 100px;
    background-color: grey;
    position: absolute;
    width: 37%;
    top: 1420px;
    left: 271px;
}
</style>


{pause up}
Is all you need!


{.unstatic}
<x-ocaml>
let ( let* ) x v = bind x v
let ( := ) v n = set_u v n
</x-ocaml>


<x-ocaml>
let x = ref 0
let { undo; _ } =
  let* () = x := 5 in
  x := 7;;
</x-ocaml>

{pause}

<x-ocaml>
let () = undo ();;
</x-ocaml>



{step}
---

{slip pause=featurelistocatooling}
---
# Tooling

{#featurelistocatooling style="display: flex; flex-wrap: wrap; justify-content: space-evenly;" children:.block children:style="margin: 10px"}
>
> {#dunefeat}
> ✅️ Dune
>
> {#merlinfeat}
> ✅️ Merlin
>
> {#ocamleglotfeat}
> ✅️ Ocaml-eglot
>
> ✅️ Ocamlformat

{exec pause down=treemd}
```slip-script
slip.setClass(document.querySelector("#dunefeat"), "ssellected", true)
```

{#treemd carousel change-page='~n:"3 5"'}
> ```
>    
>     slipshow
>     ├── docs
>     ├── src
>     │   ├── cli
>     │   ├── communication
>     │   ├── compiler
>     │   ├── engine
>     │   ├── server
>     │   ├── static_data
>     │   └── themes
>     ├── test
>     
>     
>     
>     
>     
>     
>     
>                     
>                     
>                     
>                     
> ```
>
> ```
>  
>     slipshow
>     ├── docs
>     ├── src
>     │   ├── cli
>     │   ├── communication
>     │   ├── compiler
>     │   ├── engine
>     │   ├── server
>     │   ├── static_data
>     │   └── themes
>     ├── test
>     └── vendor
>         └── github.com
>             └── panglesd
>                 ├── cmarkit
>                 ├── irmin-watcher
>                 ├── pdfjs_ocaml
>                 └── perfect-freehand-ocaml
>              
>              
>                       
>                   
> ```
>
> ```
> .── dune-workspace
> ├── slipshow
> │   ├── docs
> │   ├── src
> │   │   ├── cli
> │   │   ├── communication
> │   │   ├── compiler
> │   │   ├── engine
> │   │   ├── server
> │   │   ├── static_data
> │   │   └── themes
> │   ├── test
> │   └── vendor
> │       └── github.com
> │           └── panglesd
> │               ├── cmarkit
> │               ├── irmin-watcher
> │               ├── pdfjs_ocaml
> │               └── perfect-freehand-ocaml
> ├── sliphub
> │   └── ...
> └── slipshow-vscode
>     └── ...
> ```

{exec pause}
```slip-script
slip.setClass(document.querySelector("#dunefeat"), "ssellected", false)
slip.setClass(document.querySelector("#merlinfeat"), "ssellected", true)
slip.setClass(document.querySelector("#ocamleglotfeat"), "ssellected", true)
```

Demo

----

{step}


<!-- - A single language for browser and (static) native code -->
<!--   - Static typing, -->
<!--   - Precise compiler errors. Illustration: Add an `id` to communication message. -->
<!--   - Lovely syntax -->

<!-- {pause up} -->

<!-- A new step looks like this -->

<!-- ```ocaml -->
<!-- let elem = next_activated_elem () in -->

<!-- List.iter -->
<!--   (fun action -> maybe_activate action elem) -->
<!--   all_actions -->
<!-- ``` -->

<!-- {.block #quest} -->
<!-- How to go back? -->

<!-- ```ocaml -->
<!-- type 'a undoable = 'a * (unit -> unit) -->
<!-- ``` -->

<!-- {pause up=quest} -->
<!-- ```ocaml -->
<!-- # let set = (:=) -->
<!-- val set : 'a ref -> 'a -> unit -->
<!-- ``` -->

<!-- {carousel change-page} -->
<!-- > ```ocaml -->
<!-- > # let set_u x n = -->
<!-- >     let undo = -->
<!-- >       ?????? -->
<!-- >       ??????                -->
<!-- >     in -->
<!-- >     (x := n), undo -->
<!-- > -->
<!-- > val set : 'a ref -> 'a -> unit undoable -->
<!-- > ``` -->
<!-- > ```ocaml -->
<!-- > # let set_u x n = -->
<!-- >     let undo = -->
<!-- >       let old = !x in -->
<!-- >       fun () -> x := old -->
<!-- >     in -->
<!-- >     (x := n), undo -->
<!-- > -->
<!-- > val set : 'a ref -> 'a -> unit undoable -->
<!-- > ``` -->

<!-- Order: -->

<!-- - I'm going to highlight three things that help me write software efficiently -->
<!--   - Language -->
<!--     - First show that many features are used: -->
<!--       - ✅️ Functors -->
<!--       - ✅️ First class modules for actions (show `actions.mli` ?) -->
<!--       - ✅️ GADT to direct parsing. -->
<!--       - ✅️ Extensible variants -->
<!--       - ✅️ Polymorphic datatypes -->
<!--       - ❌ Objects -->
<!--       - ❌ Effects -->
<!--     - Then speak about undo monad -->

<!--     ```ocaml -->
<!--     type 'a with_undo = { value : 'a; undo : unit -> unit } -->

<!--     let set x v = -->
<!--       Format.printf "Setting value from %d to %d\n%!" !x v; -->
<!--       x := v -->

<!--     let ( := ) x v = set x v -->

<!--     let set_u x v = -->
<!--       let undo = -->
<!--         let old = !x in -->
<!--         fun () -> x := old -->
<!--       in -->
<!--       let value = x := v in -->
<!--       { value; undo } -->

<!--     let bind (x : 'a with_undo) (f : 'a -> 'b with_undo) : 'b with_undo = -->
<!--       let y = f x.value in -->
<!--       let undo () = -->
<!--         y.undo (); -->
<!--         x.undo () -->
<!--       in -->
<!--       { value = y.value; undo } -->

<!--     let ( let* ) x v = bind x v -->
<!--     let ( := ) v n = set_u v n -->
<!--     let x = ref 0 -->

<!--     let { undo; _ } = -->
<!--       let* () = x := 5 in -->
<!--       x := 7 -->

<!--     let () = undo ();; -->

<!--     x -->
<!--     ``` -->

<!--   - Tooling -->
<!--     - Dune vendoring -->
<!--       - Show vendoring folder -->
<!--     - Dune monorepo -->
<!--       - Show ../ folder -->
<!--     - LSP/Merlin -->
<!--       - Show how  -->
<!--   - Ecosystem -->
<!--     - cmdliner -->
<!--     - cmarkit -->
<!--     - `js_of_ocaml`, Brr and JS bindings -->
<!--     - Lambdasoup -->

<!-- TODO: speak about undo monad -->
<!--   - Many advanced features -->
<!--     - Functors and First class module: actions -->
<!--     - GADT: TODO -->
<!--     - Extensible variants: AST and Cmarkit -->
<!--     - Effects: I'm still trying -->
<!-- - Excellent tooling -->
<!--   - Dune -->
<!--     - Slipshow's build is complex -->
<!--     - Vendoring is easy -->
<!--     - Moving directories is easy -->
<!--     - Monorepoing is easy -->
<!--   - Merlin/Ocaml-lsp-server/Ocaml-eglot -->
<!--   - OCamlformat -->

<!-- (OCaml also has disappointed me. -->
<!--   * Only few choices between extra high quality libraries -->
<!--   * Compilation is a bit too fast -->
<!--   * Can't multiply a string and a float -->
<!--   * [...]) -->










<!-- --- -->

<!-- <style> -->
<!-- #emoji { -->
<!--   font-size: 10em; -->
<!-- } -->
<!-- #lock { -->
<!--   padding: 20px; -->
<!--   position: absolute; -->
<!--   left: 500px; -->
<!--   top: 400px; -->
<!--   text-align: center; -->
<!--   font-size: 1em; -->
<!--   background: rgba(255, 255, 255, 0.75); -->
<!--   border-radius: 20px; -->
<!--   border: 2px solid black; -->
<!--   z-index: 10; -->
<!-- } -->
<!-- .blur { -->
<!--   filter: blur(10px); -->
<!-- } -->
<!-- </style> -->


<!-- <\!-- {pause} -\-> -->


<!-- {#lock} -->
<!-- > [🔒]{#emoji} -->
<!-- > -->
<!-- > Unlock at FunOCaml 2025, \ -->
<!-- > Warsaw, September 15-16 -->

