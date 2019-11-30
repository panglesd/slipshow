
let intro = new Slide("intro", [], presentation, engine, {});
let base = new Slide("base", [], presentation, engine, {});
let beamerPart = new Slide("beamer-part", [], presentation, engine, {});
let futur = new Slide("futur", [], presentation, engine, {firstVisit: (slide) => {
    futur.delay = 0;
    let but = slide.query("#mouse");
    but.addEventListener("mouseenter", (ev) => {
	but.style.left = (but.style.left == "0px" ? "80%" : "0px");
    });
    but.addEventListener("click", (ev) => {
	alert("yo");
    });
    red.element.style.display = "none";
    blue.element.style.display = "none";
}});
let red = new Slide("red", [], presentation, engine, { firstVisit: (slide) => { futur.delay = 1;}});
let blue = new Slide("blue", [], presentation, engine, {});
let links = new Slide("links", [], presentation, engine, {firstVisit: (slide) => {slide.revealAll(".c1");}});

futur.setNthAction(9, (slide) => {
    slide.savedX = slide.currentX;
    slide.savedY = slide.currentY;
    engine.moveWindow(2,2,4,0,1);
});
futur.setNthAction(10, (slide) => {
    engine.moveWindow(slide.savedX,slide.savedY,1,0,1);
    red.element.style.display = "block";
    blue.element.style.display = "block";
});
futur.setNthAction(11, (slide) => {
    presentation.skipSlide({delay:1});
});

presentation.setSlides([
    intro,
    base,
    beamerPart,
    futur,
    red,
    blue,
    futur,
    links,
]);
