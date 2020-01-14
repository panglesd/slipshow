# Slip.js

OUTDATED! OUTDATED! This version of the readme is outdated with the new merge, but will be updated very soon.

## Principle

This is not another slide engine, but a slip engine with fine customization: not only on the cosmetic part, but also on the interactive part.

The engine is written in javascript and html. Once your presentation is written, open it with a (modern, i.e. not I.E.) browser, it is supposed to look the same on all browser.

The presentation consists of an infinite canvas, on which are placed a variant of slides (the *slips*). During the presentation, a 4/3 window shows the slips bits by bits. The window can move instantly, simulating presentation with slides, or in a fluid manner, as in Prezi.

In the canvas are placed not slides, but slips. A slip is a slide with no bottom limit. A slide has a bottom limit as nothing below the end of the page can be seen. However, with the sliding window effect, one can show the overflowed part of the slip by sliding it downward.

You can find two examples here:
- [The slips of my thesis](http://choum.net/panglesd/slides/slides-js/slides.html) (old version of the engine)
- [The slips to present slip](http://choum.net/panglesd/slides/slip-js/slides.html)

Do not hesitate to look at the code of the example in the folder example, both .html and .js files are commented. (This example corresponds to the slip slip presentation of the link above).

## Development
You will need [`yarn`](https://yarnpkg.com/lang/en/docs/install) (or `npm`) to manage the dependencies.

- To install the dependencies run `yarn` from the root of the cloned repository.
- To start the devellopment server run `yarn dev`.
- To build the release files use `yarn build`.

## Production usage
You can add `slip-js` as a dependency to your project (todo npm package).

Or you can use the pre-compiled files available at: (todo CI).
[https://panglesd.github.io/slip-js/dist/slip.js](https://panglesd.github.io/slip-js/dist/slip.js)
[https://panglesd.github.io/slip-js/dist/slip.css](https://panglesd.github.io/slip-js/dist/slip.css)
[https://panglesd.github.io/slip-js/dist/theorm.css](https://panglesd.github.io/slip-js/dist/theorem.css)


## Minimal example

In order to make you own presentations, you only need to include the files `slip.js`, `slip.css`, and `theorem.css`, and follow the slip structure for your html document. Here is a template:

```html todo: update
<!doctype html>
<html>
    <head>
	<title>Title</title>
	<meta charset="utf-8" />
	<link rel="stylesheet" type="text/css" href="slides.css"> 
	<link rel="stylesheet" type="text/css" href="theorem.css">
    </head>
    <body>
	<div class="cpt-slip">0</div>
	<div class="presentation">
	    <div class="slide" id="slide-id">Hello World!</div>
	</div>
	<script src="slip.js"></script>	
    </body>
</html>
```

## Writing slips
   
   You can create a new slide by creating an element `<div class="slide"></div>`. Inside is any html. If you don't like writing HTML, there are two possibilities:
   - Get a good editor so that it eases the pain,
   - Use another syntax, and convert it to html after (and add needed attributes).

   By default, slips behave just as slides. But you can specify the position of the slip in the big canvas that is the universe by adding some attributes. The attributes `pos-x` and `pos-y` specify the position, `scale` and `rotate` the scale and rotation, while `delay` specify how long it takes to move to the slip.
   ```html
   <div class="slide" id="links" pos-x="2" pos-y="2" scale="4.3" delay="3">
   ```

   Inside a slip, an element with attribute `chg-visib-at="n0 n1 n2 ..."` will be shown at times n0, n1, n2... and hidden at times -n0, -n1, -n2... For instance, `<div chg-visib-at="0 2 -3 6"></div>` will be hidden at time 0, shown at time 2, hidden at time 3, shown again at time 6.

   Similarly, an element with attribute `emphasize-at="n0 n1 n2 ..."` will be emphasized at times n0, n1, n2... For instance, `<div emphasize-at="0 2 6"></div>` will be emphasized at time 0, 2, and 6.

   Similarly, an element with attribute `down-at="n0 n1 n2 ..."` will have the universe moved so it is at the bottom of the screen at times n0, n1, n2... The same holds for `center-at`, and `up-at`, for the center and the top of the screen.

   Avoid writing javascript inside a slip. Instead, see the last section.

## Presenting you presentation

You can navigate through you slides with right arrow, and left to go back. You can go directly to the next (previous) slide by using Shift+Right (Shift+Left). You can refresh the slide by pushing "r".

You can also navigate the universe with "o,k,l,m" to move ("f" makes it faster), "i,p" to rotate and "z, Z" to zoom. 

Soon, you'll be able to have a list of your slides and go directly to the one you want by clicking on it.

## Finer control of your presentation

   You might need a better control of the flow of events. There are severals objects defined to help you do this:
     -an engine for the control of the window to the universe,
	 -a presentation for the control of the flow of the slides,
	 -one slip for each slip for controlling what happens inside a slip.
	 
   If you want to create a slip, you can do the following `let slip1 = new Slide("slide-ID", actionList, presentation, engine, options);`. The parameter `actionList` is a list of function, taking the slip as input. Each of them will be activated one after another, when the user press "Right". The parameter `options` can define several functions: `options.init(slip)` which will be called every time the slip is "re-created", `options.firstEnter(slip)` which will be called the first time one enter the slip and at each refresh, and `options.whenLeaving(slip)` which will be called when leaving.
   
   One can set the action at a specific time by `slip.setNthAction(n, action)`.
   
   Once several slips have been defined, you can define the order in which they wil be displayed with `presentation.setSlides([slip1, slip2, slip3]);`. Slips can appear multiple times, but won't be refreshed the second time.
   
   The object `presentation` allows to skip to a certain slip, without going through all the steps, with `presentation.skipSlide()`. It can also go to an arbitrary slide with `presentation.gotoSlideIndex(index)`.
   The object `engine` allows to move the window, with `engine.moveWindow(x, y, scale, rotate, delay)` and `engine.moveWindowRelative(dx, dy, dscale, drotate, delay)`. Both can be used inside slip actions.

## Examples

- [The slips of my thesis](http://choum.net/panglesd/slides/slides-js/slides.html) (old version of the engine)
- [The slips to present slip](http://choum.net/panglesd/slides/slip-js/slides.html)

## TODO

- Table of content of all slips when pressing a button,
- Better going back and slip counter,
- Wait for slips being placed before showing something, 
- More fluid transition,
- Be consistent and replace slides with slip in slip.js,
- Support for "subslips"?
- ...

   
