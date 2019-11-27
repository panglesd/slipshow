
// let engine = new Engine();
// let presentation = new Presentation(engine);

let asBeamer = new Slide("as-beamer", [], presentation, engine, {});
let beamerPart = new Slide("beamer-part", [], presentation, engine, {});

let title = new Slide("pythagore", [], presentation, engine, {});
title.setAction([
    (slide) => {
    }, (slide) => {
	slide.moveUpTo(".definition", 1);
    }, (slide) => {
	slide.moveDownTo(".theorem", 1);
    }, (slide) => {
	slide.moveCenterTo(".definition", 1);
    }
]);



let philo = new Slide("philo", [], presentation, engine, {});

// presentation.setSlides([
//     asBeamer,
//     beamerPart,
//     title,
//     philo,
// ], engine);

// let controller = new Controller(engine, presentation);
// engine.setPresentation(presentation);

// presentation.start();

// function getAnchor() {
//     var currentUrl = document.URL,
// 	urlParts   = currentUrl.split('#');
		
//     return (urlParts.length > 1) ? urlParts[1] : null;
// }
// let anchor = parseInt(getAnchor());
// if(anchor) {
//     for(let i=0;i<anchor; i++) {
// 	presentation.next();
//     }
// }
