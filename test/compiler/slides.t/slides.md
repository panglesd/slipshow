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
