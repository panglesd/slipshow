export let Controller = function (ng) {
    let engine = ng;
    this.getEngine = () => this.engine;
    this.setEngine = (ng) => this.engine = ng;

    // let mainSlip = mainS;
    // this.getMainSlip = () => mainSlip;
    // this.setMainSlip = (slip) => mainSlip = slip;

    let speedMove=1;
    document.addEventListener("keypress", (ev) => {
	if(ev.key == "f") { speedMove = (speedMove + 4)%30+1; }    
	if(ev.key == "r") { engine.getCurrentSlip().refresh(); }    
	if(ev.key == "#") {
	    document.querySelectorAll(".slip").forEach((slip) => {slip.style.zIndex = "-1";});
	    document.querySelectorAll(".background-canvas").forEach((canvas) => {canvas.style.zIndex = "1";});
	}    
    });
    document.addEventListener("keydown", (ev) => {
	let openWindowHeight = engine.getOpenWindowHeight();
	let openWindowWidth = engine.getOpenWindowWidth();
	if(ev.key == "l") { engine.moveWindowRelative( 0                          ,  (speedMove)/openWindowHeight, 0, 0, 0.1); }   // Bas
	if(ev.key == "o") { engine.moveWindowRelative( 0                          , -(speedMove)/openWindowHeight, 0, 0, 0.1); }  // Haut
	if(ev.key == "k") { engine.moveWindowRelative(-(speedMove)/openWindowWidth,  0                           , 0, 0, 0.1); }   // Gauche
	if(ev.key == "m") { engine.moveWindowRelative( (speedMove)/openWindowWidth,  0                           , 0, 0, 0.1); }   // Droite
	if(ev.key == "i") { engine.moveWindowRelative(0, 0,  0   ,  1, 0.1); }                             // Rotate 
	if(ev.key == "p") { engine.moveWindowRelative(0, 0,  0   , -1, 0.1); }                             // Unrotate
	if(ev.key == "z") { engine.moveWindowRelative(0, 0,  0.01,  0, 0.1); }                          // Zoom
	if(ev.key == "Z") { engine.moveWindowRelative(0, 0, -0.01,  0, 0.1); }                          // Unzoom
	if(ev.key == "T") {
	    engine.showToC();
	    // document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none"; 
	}   
	if(ev.key == "t") {
	    // engine.showToC();
	    document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none"; 
	}   
	if(ev.key == "ArrowRight") {
	    console.log(ev);
	    if(ev.shiftKey)
		engine.nextSlip();
	    else    
		engine.next();
	}
	else if (ev.key == "ArrowLeft") {
	    if(ev.shiftKey)
		engine.previousSlip();
	    else    
		engine.previous();
	}
	else if (ev.key == "ArrowUp") {
	    engine.pop();
	}
    });  
    
};
