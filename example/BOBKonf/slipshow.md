# Undoing in context[: Slipshow]{.unrevealed}

{draw=compiledraw}

{draw=compiledraw}

{draw=compiledraw}

{draw=compiledraw}

{draw=compiledraw}

{draw=compiledraw}

![Compiling explanation](compiling.draw){#compiledraw}

{pause draw=compiledraw}

{#cmf-addons style="margin-top:150px" children:.block children:style="height:400px; padding-right:50px; padding-left:50px; width:20%"}
> {carousel .carousel-fixed-height #carousel1}
> > ```txt
> > ## Title
> >
> > Wait for it...
> >
> > {pause}
> >
> > Surprise!{emph}
> > ```
> > {style=margin-left:-19px;margin-top:-15px}
> > ````txt
> > {exec}
> > ```slip-script
> > document
> >  .querySelectorAll
> >   (".c")
> >  .forEach(
> >     slip.reveal
> >  )
> > ```
> > ````
> >
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

{draw=compiledraw}

{draw=compiledraw}

{change-page=carousel1 draw=compiledraw}

{pause #togoback up='~margin:"15"'}

![React explanation](react.draw){#reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{draw=reactdraw}

{pause}

{.block style="margin-top:900px;font-size:2em;text-align:center;background-color:darkolivegreen;color:white" children:style="margin:0px" carousel change-page='~n:"1-3"' #carouproblem}
>
> **Problem 1**: The state coexists with an implicit state
>
> **Problem 2**: Actions are defined as transitions
>
> **Problem 3**: State transitions may take time
>
> **Problem 4**: Different requirements for both directions
>
> > **Problem 1**: The state coexists with an implicit state
> >
> > **Problem 2**: Actions are defined as transitions
> >
> > **Problem 3**: State transitions may take time
> >
> > **Problem 4**: Different requirements for both directions
> >
>
> **Problem 1**: Everything is duplicated
>
> **Problem 2**: Everything is duplicated

{center=carouproblem change-page=carouproblem}

{up='~margin:"15" togoback' unstatic=carouproblem}

{draw=reactdraw}

![Next and prev expl](next-prev.draw){#nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{draw=nextprevdraw}

{down pause .block style="margin-top:1050px;font-size:2em;text-align:center;background-color:darkolivegreen;color:white" children:style="margin:0px" carousel #pb2}
>
> **Problem 1**: Everything is duplicated
>
> **Problem 2**: Everything is duplicated

{change-page=pb2}

{up='~margin:"15" togoback' unstatic=pb2}


{draw=nextprevdraw}


{draw=reactdraw}

![Only next solution](only-next.draw){#onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{draw=onlynextdraw}

{down pause .block style="margin-top:1000px;font-size:2em;text-align:center;background-color:darkolivegreen;color:white" children:style="margin:0px" carousel #pb3}
>
> **Problem 1**: ...
>
> **Challenge**: How to return your undo in an ergonomic way?

{change-page="~n:all pb3"}
