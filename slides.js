// We want a fine control, so we don't let the presentation order the slips by their order of appearance in the HTML file.
// (this is mostly because we want the slips "red" and "blue" in the middle of the slip "future")

// Creation of slips
let intro = new Slide("intro", [], presentation, engine, {});
let base = new Slide("base", [], presentation, engine, {});
let beamerPart = new Slide("beamer-part", [], presentation, engine, {});

// All JS added must be done in the init or the firstVisit function
let future = new Slide("future", [], presentation, engine, {firstVisit: (slide) => {
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

// When we enter red, we want that when we go back to future we do that "smoothly" (in 1s)
let red = new Slide("red", [], presentation, engine, { firstVisit: (slide) => { future.delay = 1;}});
let blue = new Slide("blue", [], presentation, engine, {});

// the "c1" elements have to be hidden for when "future" unzoom. They have to be shown as soon as we enter this slip.
let links = new Slide("links", [], presentation, engine, {firstVisit: (slide) => {slide.revealAll(".c1");}});

// at step 9, future unzooms the window
future.setNthAction(9, (slide) => {
    slide.savedX = slide.currentX; // saving initial coordinates inside slide
    slide.savedY = slide.currentY; // so that they are accessible in the next action
    engine.moveWindow(2,2,4,0,1);
});
future.setNthAction(10, (slide) => {
    engine.moveWindow(slide.savedX,slide.savedY,1,0,1); // recovering initial position
    red.element.style.display = "block";
    blue.element.style.display = "block";
});
future.setNthAction(11, (slide) => {
    presentation.skipSlide({delay:1}); // Leaving "future" without finishing it
});

presentation.setSlides([
    intro,
    base,
    beamerPart,
    future,
    red,
    blue,
    future, // coming back to the unfinished "future"
    links,
]);
