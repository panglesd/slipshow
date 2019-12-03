// We want a fine control, so we don't let the presentation order the slips by their order of appearance in the HTML file.
// (this is mostly because we want the slips "red" and "blue" in the middle of the slip "future")

// Creation of slips
let intro = new Slip("intro", [], presentation, engine, {});
let base = new Slip("base", [], presentation, engine, {});
let beamerPart = new Slip("beamer-part", [], presentation, engine, {});

// All JS added must be done in the init or the firstVisit function
let future = new Slip("future", [], presentation, engine, {firstVisit: (slip) => {
    let but = slip.query("#mouse");
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
let red = new Slip("red", [], presentation, engine, { firstVisit: (slip) => { future.delay = 1;}});
let blue = new Slip("blue", [], presentation, engine, {});

// the "c1" elements have to be hidden for when "future" unzoom. They have to be shown as soon as we enter this slip.
let links = new Slip("links", [], presentation, engine, {firstVisit: (slip) => {slip.revealAll(".c1");}});

// at step 9, future unzooms the window
future.setNthAction(9, (slip) => {
    slip.savedX = slip.currentX; // saving initial coordinates inside slip
    slip.savedY = slip.currentY; // so that they are accessible in the next action
    engine.moveWindow(2,2,4,0,1);
});
future.setNthAction(10, (slip) => {
    engine.moveWindow(slip.savedX,slip.savedY,1,0,1); // recovering initial position
    red.element.style.display = "block";
    blue.element.style.display = "block";
});
future.setNthAction(11, (slip) => {
    presentation.skipSlip({delay:1}); // Leaving "future" without finishing it
});

presentation.setSlips([
    intro,
    base,
    beamerPart,
    future,
    red,
    blue,
    future, // coming back to the unfinished "future"
    links,
]);
