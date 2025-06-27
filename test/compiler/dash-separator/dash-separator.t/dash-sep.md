<style>
  .show-border, .show-border * {
    border: 3px solid black;
    border-radius: 10px;
    padding: 10px;
  }
</style>

Asterisks still allow horizontal lines:

***

For instance this one

{.show-border1}
> aaa
>
> ---
>
> bbb
>
> ----
>
> cc
>
> ----
>
> ddd
>
> ---
>
> eee

{.show-border2}
> ---
>
> aa
>
> ---
>
> bb

{.show-border3}
> {.c1}
> ---
>
> aa
>
> {.c2}
> ---
>
> bb
