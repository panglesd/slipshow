<style>
  .show-border, .show-border * {
    border: 3px solid black;
    border-radius: 10px;
    padding: 10px;
  }
</style>

{.show-border}
> aa
>
> ---
>
> bbb
>
> ----
>
> ccc
>
> ----
>
> ddd
>
> ---
>
> ee

is equivalent to

{.show-border}
> > aa
>
> > > bbb
> >
> > > ccc
> >
> > > ddd
>
> > ee
