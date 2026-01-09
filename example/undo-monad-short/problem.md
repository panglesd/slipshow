# Bidirectional computing

![](compile.draw){#compiledraw}

{#cmf-addons .block}
> ```txt
> ## Title
>
> Wait for it...
>
> {pause}
>
> Surprise!{emph}
> ```
> ---
>
> ## Title
>
> Wait for it...
>
> {draw=compiledraw}
>
> {draw=compiledraw}
>
> {pause}
>
> {draw=compiledraw}
>
> Surprise!{emph}

{draw=compiledraw}

{draw=compiledraw}

{down="~margin:102 cmf-addons"}

![](bas_solution.draw){#bad_solution draw}

{draw=bad_solution}

{draw=bad_solution}

{draw=bad_solution}

{down="~margin:127 cmf-addons"}

{draw=bad_solution}

{draw=bad_solution}

{.block #limitations pause up title="Limitations"}
> - What is a "state"? How to include everything?
>
> - States don't account well for transitions.
>
> - I want fine control over transitions

![](good_sol.draw){#good_sol draw}

{draw=good_sol}

{draw=good_sol}

{draw=good_sol}

{draw=good_sol}

{draw=good_sol}

<style>
#limitations {
  margin-top:1500px;
}
#cmf-addons {
  display: flex;
  justify-content: space-around;
  align-items: center;
}
.emphasized {
  font-weight: bold;
}
</style>
