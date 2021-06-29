// import Hammer from 'hammerjs';

export default function (ng) {
    let engine = ng;
    this.getEngine = () => this.engine;
    this.setEngine = (ng) => this.engine = ng;

    let activated = true;
    this.activate = () => {
	activated = true;
    };
    this.deactivate = () => {
	activated = false;
    };
    
    let left_keys = ["k"],
	right_keys = ["m"],
	up_keys = ["o"],
	down_keys = ["l"],
	rotate_keys = ["i"],
	unrotate_keys = ["p"],
	zoom_keys = ["z"],
	unzoom_keys = ["Z"],
	show_toc_keys = ["T"],
	show_toc2_keys = ["t"],
	next_keys = ["ArrowRight", "ArrowDown"],
	previous_keys = ["ArrowLeft", "ArrowUp"],
	refresh_keys = ["r"],
	change_speed_keys = ["f"],
	up_slip_keys = [],
	draw_on_slip_keys = ["w"],
	erase_on_slip_keys = ["W"],
	highlight_on_slip_keys = ["h"],
	erase_highlight_on_slip_keys = ["H"],
	stop_writing_on_slip_keys = ["x"],
	background_canvas_keys = ["#"];

    // let mainSlip = mainS;
    // this.getMainSlip = () => mainSlip;
    // this.setMainSlip = (slip) => mainSlip = slip;

    // let mc = new Hammer(document.body);
    // mc.on("swipe", (ev) => {
    // 	if (ev.direction == 2) {
    // 	    engine.next();
    // 	}
    // 	if (ev.direction == 4) {
    // 	    engine.previous();
    // 	}
    // });
    let speedMove=1;
    document.addEventListener("keypress", (ev) => {
	if(change_speed_keys.includes(ev.key) && activated) { speedMove = (speedMove + 4)%30+1; }    
	if(refresh_keys.includes(ev.key) && activated) { engine.getCurrentSlip().refresh(); }    
	if(draw_on_slip_keys.includes(ev.key) && activated) { engine.setTool("drawing"); }    
	if(erase_on_slip_keys.includes(ev.key) && activated) { engine.setTool("drawing-erase"); }    
	if(highlight_on_slip_keys.includes(ev.key) && activated) { engine.setTool("highlighting"); }    
	if(erase_highlight_on_slip_keys.includes(ev.key) && activated) { engine.setTool("highlighting-erase"); }
	if(stop_writing_on_slip_keys.includes(ev.key) && activated) { engine.setTool("no-tool"); }    
	if(background_canvas_keys.includes(ev.key) && activated) {
	    document.querySelectorAll("slip-slip").forEach((slip) => {slip.style.zIndex = "-1";});
	    document.querySelectorAll(".background-canvas").forEach((canvas) => {canvas.style.zIndex = "1";});
	}    
    });
    document.addEventListener("keydown", (ev) => {
	let openWindowHeight = engine.getOpenWindowHeight();
	let openWindowWidth = engine.getOpenWindowWidth();
	if(down_keys.includes(ev.key) && activated) { engine.moveWindowRelative( 0                          ,  (speedMove)/openWindowHeight, 0, 0, 0.1); }   // Bas
	if(up_keys.includes(ev.key) && activated) { engine.moveWindowRelative( 0                          , -(speedMove)/openWindowHeight, 0, 0, 0.1); }  // Haut
	if(left_keys.includes(ev.key) && activated) { engine.moveWindowRelative(-(speedMove)/openWindowWidth,  0                           , 0, 0, 0.1); }   // Gauche
	if(right_keys.includes(ev.key) && activated) { engine.moveWindowRelative( (speedMove)/openWindowWidth,  0                           , 0, 0, 0.1); }   // Droite
	if(rotate_keys.includes(ev.key) && activated) { engine.moveWindowRelative(0, 0,  0   ,  1, 0.1); }                             // Rotate 
	if(unrotate_keys.includes(ev.key) && activated) { engine.moveWindowRelative(0, 0,  0   , -1, 0.1); }                             // Unrotate
	if(zoom_keys.includes(ev.key) && activated) { engine.moveWindowRelative(0, 0,  0.01,  0, 0.1); }                          // Zoom
	if(unzoom_keys.includes(ev.key) && activated) { engine.moveWindowRelative(0, 0, -0.01,  0, 0.1); }                          // Unzoom
	if(show_toc_keys.includes(ev.key) && activated) {
	    engine.showToC();
	    // document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none"; 
	}   
	if(show_toc2_keys.includes(ev.key) && activated) {
	    // engine.showToC();
	    document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none"; 
	}   
	if(next_keys.includes(ev.key) && activated) {
	    console.log(ev);
	    if(ev.shiftKey)
		engine.nextSlip();
	    else    
		engine.next();
	}
	else if (previous_keys.includes(ev.key) && activated) {
	    if(ev.shiftKey)
		engine.previousSlip();
	    else    
		engine.previous();
	}
	else if (up_slip_keys.includes(ev.key) && activated) {
	    engine.pop();
	}
    });    
};
