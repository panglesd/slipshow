# Monads: a design pattern

{style="display:flex;gap:20px;justify-content:space-around"}
> ### Statements
>
> ```javascript
> let x = <expr>
>
> if(<expr>) {
>   <statement>
> } else {
>   <statement>
> }
>
> <statement> ; <statement>
> ```
>
> {#batman}
> ```
> do_the_laundry();
> go_to_the_cinema("Batman");
> finish_your_presentation()
> ```
> ---
>
> ### Expressions
>
> ```javascript
> 5
>
> "hello"
>
> f(<expr>,<expr>)
>
> <expr> ? <expr> : <expr>
> ```

![](ooe.draw){draw #ooe}

{up=batman}

```javascript
function with_effect(x) {
  console.log(x);
  return x
}

with_effect(false) || with_effect(true)

```

{draw=ooe}

{pause}
```javascript

function or (a, b) {
  return a || b
}

or(with_effect(false), with_effect(true))
```

{draw=ooe}

{up pause}
## Functional Programming language only have expressions

```ocaml
if <expr> then <expr> else <expr>

<expr> ; <expr>

"hello"

(fun n -> n + 1)
```

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{pause up style="margin-top:600px"}
## Encoding computations: the Monad design pattern

- Type for computations:
  ```
  type 'a t
  ```

- Trivial computation:
  ```
  return x
  ```

- Chaining computations
  ```
  let x := computation1;
  computation2(x)
  ```

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{draw=ooe}

{style=margin-top:150px pause}
## If you define `t`, `return` and `;`, you can represent{style=color:red} all computations

- ```
  val run : 'a t -> 'a
  ```

<style>
code { background-color:#f3f3f3; color:#444}
</style>
