
{#slide1 step enter slide}
Aren’t you just bored with all those slides-based presentations?

{#slide2 step enter slide}
Don’t you think that presentations given in modern browsers shouldn’t copy the limits of ‘classic’ slide decks?

{#slide3 step enter slide}
Would you like to impress your audience with stunning visualization of your talk?

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

{pause enter=idslide}
yo

{pause enter=idslide2}
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
