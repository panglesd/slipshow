# slipshow

> This is not another slideshow html5 engine, but a slip engine.

A slipshow is a presentation in between the standard slide-based slideshow and the prezi-like presentation. It is stored in an html file that you open in a browser.

The presentation consists of an infinite canvas, on which are placed a variant of slides (the *slips*). During the presentation, a 4/3 window shows the slips. The window can move instantly, simulating presentation with slides, or in a fluid manner, as in Prezi.

In the canvas are placed not slides, but slips. A slip is a slide with no bottom limit. A slide has a bottom limit as nothing below the end of the page can be seen. However, with the sliding window effect, one can show the overflowed part of the slip by sliding it downward.

## Example

You can find several example of slip presentation, from different versions of slip. As they were from early stage of developpement, looking at the source code can be helpful but many things may have changed. Only the official example, tutorial and documentation are kept up to date.

- [The slips to present slip](http://choum.net/panglesd/slides/slip-js/slides.html)
- [The slips of my thesis](http://choum.net/panglesd/slides/slides-js/slides.html) (old version of the engine)

##  Tutorial, API and Documentation

You can find an extensive documentation, with a tutorial at the readthedocs [documentation](https://slipshow.readthedocs.io)

## Very quick start

If you do not want to read any of the tutorial but you still want to test a slipshow, type the following in an empty directory:

```
$ npm install slipshow
$ npx new-slipshow > test-slipshow.html
```
This will create an html file called `test-slipshow.html`. Open this file in a browser and you are done!

## Contributing

You can issue a Pull Request of any kind, report a bug, ask for a new feature, suggest or PR an enhancement on the documentation...

## License

MIT

