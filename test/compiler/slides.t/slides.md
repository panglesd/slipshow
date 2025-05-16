
{style="display: flex"}
> {#slide1 slide style="flex: 1 1 auto;"}
> Aren’t you just bored with all those slides-based presentations?
>
> {#slide2 slide style="flex: 1 1 auto;"}
> Don’t you think that presentations given in modern browsers shouldn’t copy the limits of ‘classic’ slide decks?
>
> {#slide3 slide style="flex: 1 1 auto;"}
> > Would you like to impress your audience with stunning visualization of your talk?

{pause focus-at-unpause=slide1}

{pause unfocus-at-unpause focus-at-unpause=slide2}

{pause unfocus-at-unpause focus-at-unpause=slide3}

{pause unfocus-at-unpause}

{slide #idslide}
> Hello this is a slide
>
> {slide}
> > Hello !
> > 
> > {slide}
> > > Hello !
> > > 
> > > {slide}
> > > > Hello !
> > > > 
> > > > {slide}
> > > > > Hello !
> > > > > 
> > > > > {slide}
> > > > > > Hello !
> > > > > > 
> > > > > > {.box #box2}
> > > > > > Yo !!
>
> {slide #idslide2}
> > This is a subslide

{#box}

Hello

{pause focus-at-unpause=idslide}
yo

{pause unfocus-at-unpause}

{pause focus-at-unpause=idslide2}
yo

{pause unfocus-at-unpause}

{pause focus-at-unpause=box}
yo

{pause unfocus-at-unpause}

{pause focus-at-unpause=box2}
yo


<style>
  #idslide {
    background-color:red;
  }

  #idslide2 {
    background-color:yellow;
  }

  #box, .box {
    width: 700px;
    height: 520px;
    background-color:green;
    border: 10px solid black;
  }
</style>
