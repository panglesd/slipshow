let engine = new Engine(document.querySelector("#rootSlip"));
let rootSlip = engine.getRootSlip();
// let rootSlip = new Slip("rootSlip", [], engine, {});
engine.setRootSlip(rootSlip);
//rootSlip.setEngine(engine);
// We want a fine control, so we don't let the presentation order the slips by their order of appearance in the HTML file.
// (this is mostly because we want the slips "red" and "blue" in the middle of the slip "future")

// Creation of slips
let intro = new Slip("intro", "Slip Intro", [], engine, {});
let base = new Slip("base", "Slip Basics", [], engine, {});
let beamerPart = new Slip("beamer-part", "Boring part of Slip", [], engine, {});

// All JS added must be done in the init or the firstVisit function
let future = new Slip("future", "Fun part of Slip", [], engine, {init: (slip) => { slip.delay = 0;}});

future.setNthAction(0, (slip) => {
    let but = slip.query("#mouse");
    but.addEventListener("mouseenter", (ev) => {
	but.style.left = (but.style.left == "0px" ? "80%" : "0px");
    });
    but.addEventListener("click", (ev) => {
	alert("yo");
    });
    red.element.style.display = "none";
    blue.element.style.display = "none";
});
future.setNthAction(1, (slip) => {
    slip.delay = 1;
});
// When we enter red, we want that when we go back to future we do that "smoothly" (in 1s)
let red = new Slip("red", "red Slip", [], engine, { firstVisit: (slip) => { future.delay = 1;}});

let blue = new Slip("blue", "blue Slip", [], engine, {});

// let scaleTest = new Slip("scale-test", [], presentation, engine, {});


// the "c1" elements have to be hidden for when "future" unzoom. They have to be shown as soon as we enter this slip.
// let links = new Slip("links", [], engine, {firstVisit: (slip) => {slip.revealAll(".c1");}});

// at step 9, future unzooms the window
future.setNthAction(10, (slip) => {
    slip.savedX = slip.currentX; // saving initial coordinates inside slip
    slip.savedY = slip.currentY; // so that they are accessible in the next action
    engine.moveWindow(2,2,4,0,1);
});
future.setNthAction(11, (slip) => {
    engine.moveWindow(slip.savedX,slip.savedY,1,0,1); // recovering initial position
    red.element.style.display = "inline-block";
    blue.element.style.display = "inline-block";
});
future.setNthAction(12, red);
future.setNthAction(13, blue);
// (slip) => {
// 	// presentation.skipSlip({delay:1}); // Leaving "future" without finishing it
// });

rootSlip.setAction([
    intro,
    base,
    beamerPart,
    future,
    // scaleTest,
    // blue,
    //    future, // coming back to the unfinished "future"
    //    links,
    // (slip) => {
    
    // }
]);
// presentation.setSlips([
//     intro,
//     base,
//     beamerPart,
//     future,
//     // scaleTest,
//     blue,
//     future, // coming back to the unfinished "future"
//     links,
// ]);
let controller = new Controller(engine);
