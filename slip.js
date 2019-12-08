function parseAndFormat () {
    let presentationElement = document.querySelector(".presentation");
    presentationElement.innerHTML =
'	<div id="open-window">\
	    <div class="format-container">\
	    <div class="rotate-container">\
		<div class="scale-container">\
		    <div class="universe movable" id="universe">\
			<div width="10000" height="10000" class="fog"></div>\
			<canvas style="position:absolute;top:0;left:0;z-index:-2" width="10000" height="10000" id="globalCanvas" class="background-canvas"></canvas>\
' + presentationElement.innerHTML + '\
		    </div>\
		</div>\
		</div>\
	    </div>\
	</div>\
	<div class="cpt-slip">0</div>';
    presentationElement.querySelectorAll(".slip").forEach((slipElem) => {
	slipElem.innerHTML = '\
    <div class="slip-rotate-container"><canvas style="position:absolute;top:0;left:0;z-index:-2" width="1440" height="1080" class="background-canvas" id="canvas-'+slipElem.id+'"></canvas><div class="slip-container">'+ slipElem.innerHTML + '\
</div>';
    });
    // document.querySelector(".globalCanvas").addEventListener("click", (ev) => { console.log("vous avez cliquez aux coordonées : ", ev.layerX, ev.layerY); });
    document.querySelectorAll(".background-canvas").forEach((elem)=> {elem.addEventListener("click", (ev) => { console.log("vous avez cliquez aux coordonnées : ", ev.layerX, ev.layerY); });});
    
}
parseAndFormat();

let Engine = function() {
    // Constants
    document.body.style.cursor = "auto";
    let timeOutIds = [];
    document.body.addEventListener("mousemove", (ev) => {
	timeOutIds.forEach((id) => { clearTimeout(id); });
	document.body.style.cursor = "auto";
	timeOutIds.push(setTimeout(() => { document.body.style.cursor = "none";}, 5000));
    });
    let openWindow = document.querySelector("#open-window");
    let universe = document.querySelector("#universe");
    let slips = universe.querySelectorAll(".slip");
    let browserHeight, openWindowWidth;
    let browserWidth, openWindowHeight;
    this.getOpenWindowHeight = () => openWindowHeight;
    this.getOpenWindowWidth = () => openWindowWidth;

    let winX, winY;
    let currentScale, currentRotate;

    this.moveWindow = function (x, y, scale, rotate, delay) {
	console.log("move to", x, y, "with scale, rotate, delay", scale, rotate, delay);
	currentScale = scale;
	currentRotate = rotate;
	winX = x ;
	winY = y;
	console.log(x,y);
	setTimeout(() => {
	    document.querySelector(".scale-container").style.transitionDuration = delay+"s";
	    document.querySelector(".rotate-container").style.transitionDuration = delay+"s";
	    universe.style.transitionDuration = delay+"s, "+delay+ "s"; 
	    universe.style.left = -(x*1440 - 1440/2)+"px";
	    universe.style.top = -(y*1080 - 1080/2)+"px";
	    document.querySelector(".scale-container").style.transform = "scale("+(1/scale)+")";
	    document.querySelector(".rotate-container").style.transform = "rotate("+(rotate)+"deg)";
	},0);
    };
    this.moveWindowRelative = function(dx, dy, dscale, drotate, delay) {
	this.moveWindow(winX+dx, winY+dy, currentScale+dscale, currentRotate+drotate, delay);
    };
    this.placeSlips = function () {
	let posX = 0.5;
	let posY = 0.5;
	slips.forEach((slip) => {
	    let x=parseFloat(slip.getAttribute("pos-x")), y=parseFloat(slip.getAttribute("pos-y"));
	    let scale = parseFloat(slip.getAttribute("scale"));
	    let rotate = 0;
	    scale = isNaN(scale) ? 1 : scale ;
	    x = (isNaN(x) ? posX : x);
	    y = (isNaN(y) ? posY : y);
	    slip.setAttribute("pos-x", x);
	    slip.setAttribute("pos-y", y);
	    slip.setAttribute("scale", scale);
	    slip.setAttribute("rotate", rotate);
	    posX = x + 1;
	    posY = y;
	    slip.style.top = (y*1080 - 1080/2)+"px";
	    slip.style.left = (x*1440 - 1440/2)+"px";
	    if(!slip.classList.contains("permanent"))
		slip.style.zIndex = "-1";
	    slip.style.transformOrigin = "50% 50%";
	    slip.style.transform = "scale("+scale+")";

	});	
    };
    this.placeSlips();
    this.placeOpenWindow = function () {
	browserHeight = window.innerHeight;
	browserWidth = window.innerWidth;
	if(browserHeight/3 < browserWidth/4) {
	    openWindowWidth = Math.floor((browserHeight*4)/3);
	    openWindowHeight = browserHeight;
	    openWindow.style.left = ((window.innerWidth - openWindowWidth) /2)+"px";
	    openWindow.style.right = ((window.innerWidth - openWindowWidth) /2)+"px";
	    openWindow.style.width = (openWindowWidth)+"px";
	    openWindow.style.top = "0";
	    openWindow.style.bottom = "0";
	    openWindow.style.height = (openWindowHeight)+"px";
	}
	else {
	    openWindowHeight = Math.floor((browserWidth*3)/4);
	    openWindowWidth = browserWidth;
	    openWindow.style.top = ((window.innerHeight - openWindowHeight) /2)+"px";
	    openWindow.style.bottom = ((window.innerHeight - openWindowHeight) /2)+"px";
	    openWindow.style.height = (openWindowHeight)+"px";
	    openWindow.style.right = "0";
	    openWindow.style.left = "0";
	    openWindow.style.width = openWindowWidth+"px";
	}
	document.querySelector(".scale-container").style.transformOrigin = (1440/2)+"px "+(1080/2)+"px";
	document.querySelector(".rotate-container").style.transformOrigin = (1440/2)+"px "+(1080/2)+"px";
	document.querySelector(".format-container").style.transform = "scale("+(openWindowWidth/1440)+")";
	document.querySelector(".cpt-slip").style.right =  (parseInt(openWindow.style.left)) + "px";
	document.querySelector(".cpt-slip").style.bottom =  "0";
	document.querySelector(".cpt-slip").style.zIndex =  "10";
    };
    this.placeOpenWindow();
    window.addEventListener("resize", (ev) => {
	this.placeOpenWindow();
	this.moveWindow(winX, winY, currentScale, currentRotate, 0);
    });
    
};

let Controller = function (ng, pres) {
    let engine = ng;
    this.getEngine = () => this.engine;
    this.setEngine = (ng) => this.engine = ng;

    let presentation = pres;
    this.getPresentation = () => presentation;
    this.setPresentation = (pres) => presentation = pres;

    let speedMove=1;
    document.addEventListener("keypress", (ev) => {
	if(ev.key == "f") { speedMove = (speedMove + 4)%30+1; }    
	if(ev.key == "r") { presentation.refresh(); }    
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
	if(ev.key == "ArrowRight") {
	    console.log(ev);
	    if(ev.shiftKey)
		presentation.nextSlip();
	    else    
		presentation.next();
	}
	else if (ev.key == "ArrowLeft") {
	    if(ev.shiftKey)
		presentation.previousSlip();
	    else    
		presentation.previous();
	}
    });  
    
};


function Slip (name, actionL, present, ng, options) {
    let engine = ng;
    this.getEngine = () => engine;
    this.setEngine = (ng) => engine = ng;
    
    let presentation = present;
    this.getPresentation = () => presentation;
    this.setPresentation = (present) => presentation = present;
    
    this.element = document.querySelector(".slip#"+name);
    let initialHTML = this.element.outerHTML;
    let innerHTML = this.element.innerHTML;

    this.x = parseFloat(this.element.getAttribute("pos-x"));
    this.y = parseFloat(this.element.getAttribute("pos-y"));
    this.currentX = this.x;
    this.currentY = this.y;
    this.scale = parseFloat(this.element.getAttribute("scale"));
    this.rotate = parseFloat(this.element.getAttribute("rotate"));
    this.delay = isNaN(parseFloat(this.element.getAttribute("delay"))) ? 0 : (parseFloat(this.element.getAttribute("delay")));

    this.query = (quer) => this.element.querySelector(quer);
    this.queryAll = (quer) => this.element.querySelectorAll(quer);
    let actionList = actionL;
    let actionIndex=0;
    this.setActionIndex = (actionI) => actionIndex = actionI;
    this.getActionIndex = () => actionIndex;
    this.setAction = (actionL) => {actionList = actionL;};
    this.setNthAction = (n,action) => {actionList[n] = action;};

    this.hideAndShow = () => {
	this.queryAll("*[mk-hidden-at]").forEach((elem) => {
	    let hiddenAt = elem.getAttribute("mk-hidden-at").split(" ").map((str) => parseInt(str));
	    if(hiddenAt.includes(actionIndex))
		elem.style.opacity = "0";});	
	this.queryAll("*[mk-visible-at]").forEach((elem) => {
	    let visibleAt = elem.getAttribute("mk-visible-at").split(" ").map((str) => parseInt(str));
	    if(visibleAt.includes(actionIndex))
		elem.style.opacity = "1";});	
	this.queryAll("*[mk-emphasize-at]").forEach((elem) => {
	    let emphAt = elem.getAttribute("mk-emphasize-at").split(" ").map((str) => parseInt(str));
	    if(emphAt.includes(actionIndex))
		elem.classList.add("emphasize");});	
	this.queryAll("*[mk-unemphasize-at]").forEach((elem) => {
	    let unemphAt = elem.getAttribute("mk-unemphasize-at").split(" ").map((str) => parseInt(str));
	    if(unemphAt.includes(actionIndex))
		elem.classList.remove("emphasize");});	
	this.queryAll("*[emphasize-at]").forEach((elem) => {
	    let emphAt = elem.getAttribute("emphasize-at").split(" ").map((str) => parseInt(str));
	    if(emphAt.includes(actionIndex))
		elem.classList.add("emphasize");
	    else
		elem.classList.remove("emphasize");
	});	
	this.queryAll("*[chg-visib-at]").forEach((elem) => {
	    let visibAt = elem.getAttribute("chg-visib-at").split(" ").map((str) => parseInt(str));
	    if(visibAt.includes(actionIndex))
		elem.style.opacity = "1";
	    if(visibAt.includes(-actionIndex))
		elem.style.opacity = "0";
	});	
	this.queryAll("*[static-at]").forEach((elem) => {
	    let staticAt = elem.getAttribute("static-at").split(" ").map((str) => parseInt(str));
	    if(staticAt.includes(-actionIndex)){
		elem.style.position = "absolute";
		elem.style.visibility = "hidden";
	    }
	    if(staticAt.includes(actionIndex)) {
		elem.style.position = "static";
		elem.style.visibility = "visible";
	    }
	});	    
    };
    
    this.next = function (presentation) {
	if(actionIndex >= this.getMaxNext())
	    return false;
	actionIndex = actionIndex+1;
	this.hideAndShow();
	// setTimeout(() => {
	    this.queryAll("*[down-at]").forEach((elem) => {
	    let goDownTo = elem.getAttribute("down-at").split(" ").map((str) => parseInt(str));
	    if(goDownTo.includes(actionIndex))
//		setTimeout(() => {
		this.moveDownTo(elem, 1);
//		}, 0);
	    });
	this.queryAll("*[up-at]").forEach((elem) => {
	    let goTo = elem.getAttribute("up-at").split(" ").map((str) => parseInt(str));
	    if(goTo.includes(actionIndex))
		this.moveUpTo(elem, 1);});
	this.queryAll("*[center-at]").forEach((elem) => {
	    let goDownTo = elem.getAttribute("center-at").split(" ").map((str) => parseInt(str));
	    if(goDownTo.includes(actionIndex))
		this.moveCenterTo(elem, 1);});
	if(typeof actionList[actionIndex-1] == "function")
	    actionList[actionIndex-1](this);
	// }, 0);
	return true;
    };
    this.firstVisit = () => {
	if(options.firstVisit)
	    options.firstVisit(this);
    };
    this.init = () => {
	this.queryAll("*[chg-visib-at]").forEach((elem) => {
	    elem.style.opacity = "0";
	});	
	this.queryAll("*[static-at]").forEach((elem) => {
	    elem.style.position = "absolute";
	    elem.style.visibility = "hidden";
	});	
	this.hideAndShow();
	if(options.init)
	    options.init(this);
    };
    this.whenLeaving = () => {
	if(options.whenLeaving)
	    options.whenLeaving(this);
    };
	
    this.refresh = () => {
	this.setActionIndex(0);
	console.log(this.element);
	// this.element.outerHTML = initialHTML;
	this.element.innerHTML = innerHTML;
	if(typeof hljs != "undefined")
	    document.querySelectorAll('pre code').forEach((block) => {
		hljs.highlightBlock(block);
	    });
	if(MathJax && typeof MathJax.typeset == "function")
	    MathJax.typeset();
	else if (MathJax && MathJax.Hub && typeof MathJax.Hub.Typeset == "function")
	    MathJax.Hub.Typeset();
	this.init();
	this.firstVisit();
	console.log("ai", actionIndex);
    };
    this.init(this, presentation, engine);
    this.moveUpTo = (selector, delay,  offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0.0125;
	    let d = ((elem.offsetTop)/1080-offset)*this.scale;
	    this.currentX = this.x;
	    this.currentY = this.y+d;
	    engine.moveWindow(this.x, this.y+d, this.scale, this.rotate, delay);
	},0);
    };
    this.moveDownTo = (selector, delay, offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0.0125;
	    let d = ((elem.offsetTop+elem.offsetHeight)/1080 - 1 + offset)*this.scale;
	    this.currentX = this.x;
	    this.currentY = this.y+d;
	    engine.moveWindow(this.x, this.y+d, this.scale, this.rotate, delay);
	},0);
    };
    this.moveCenterTo = (selector, delay, offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0;
	    let d = ((elem.offsetTop+elem.offsetHeight/2)/1080-1/2+offset)*this.scale;
	    this.currentX = this.x;
	    this.currentY = this.y+d;
	    engine.moveWindow(this.x, this.y+d, this.scale, this.rotate, delay);
	},0);
    };
    this.reveal = (selector) => {
	this.query(selector).style.opacity = "1";
    };
    this.revealAll = (selector) => {
	this.queryAll(selector).forEach((elem) => { elem.style.opacity = "1";});
    };
    this.hide = (selector) => {
	this.query(selector).style.opacity = "0";
    };
    this.hideAll = (selector) => {
	this.queryAll(selector).forEach((elem) => { elem.style.opacity = "0";});
    };
    this.getMaxNext = () => {
	let maxTemp = actionList.length;
	["mk-visible-at",
	 "mk-hidden-at",
	 "mk-emphasize-at",
	 "mk-unemphasize-at",
	 "emphasize-at",
	 "chg-visib-at",
	 "up-at",
	 "down-at",
	 "center-at",
	 "static-at",
	].forEach((attr) => {
	     this.queryAll("*["+attr+"]").forEach((elem) => {
		 elem.getAttribute(attr).split(" ").forEach((strMax) => {
		     maxTemp = Math.max(Math.abs(parseInt(strMax)),maxTemp);
		 });
	     });
	 });
	return maxTemp;	
    };
}



let Presentation = function (ng, ls) {
    if(!ls)
	ls = Array.from(document.querySelectorAll(".slip")).map((elem) => { return new Slip(elem.id, [], this, ng, {});});
    console.log(ls);
    // let cpt = 0;
    // Taken from https://selftaughtjs.com/algorithm-sundays-converting-roman-numerals
    // Use in showing roman numbers for slip number
    function toRoman(num) {
	var result = '';
	var decimal = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
	var roman = ["M", "CM","D","CD","C", "XC", "L", "XL", "X","IX","V","IV","I"];
	for (var i = 0;i<=decimal.length;i++) {
	    while (num%decimal[i] < num) {     
		result += roman[i];
		num -= decimal[i];
	    }
	}
	return result;
    }
    this.getCpt = () => {
	return [
	    this.getSlips().findIndex((slip) => {return slip == this.getCurrentSlip();}),
	    this.getCurrentSlip().getActionIndex()
	];
    };
    this.setCpt = () => {
	let cpt = this.getCpt();
	document.querySelector(".cpt-slip").innerText = (toRoman(cpt[0]+1)+"."+(cpt[1]+1));
    };
    let engine = ng;
    this.getEngine = () => this.engine;
    this.setEngine = (ng) => this.engine = ng;
    let listSlips = ls || [];
    let slipIndex = 0;
    this.getSlips = () => listSlips;
    this.setSlips = (ls) => listSlips = ls;
    this.getCurrentSlip = () => listSlips[slipIndex];
    this.gotoSlip = function(slip, options) {
	options = options ? options : {};
	console.log("options is ", options);
	// let x = slip.x, y = slip.y;
	// let scale = slip.scale, rotate = slip.rotate, delay = slip.delay;
	// console.log(x,y, scale, rotate);
	setTimeout(() => {
	    engine.moveWindow(slip.currentX, slip.currentY, slip.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	},0);
    };
    this.gotoSlipIndex = (index, options) => {
	// if(!listSlips[slipIndex].element.classList.contains("permanent"))
	//     listSlips[slipIndex].element.style.zIndex = "-1";
	slipIndex = index;
	// listSlips[slipIndex].element.style.zIndex = "1";
	this.gotoSlip(listSlips[slipIndex], options);
	if(!listSlips[slipIndex].visited) {
	    listSlips[slipIndex].visited = true;
	    listSlips[slipIndex].firstVisit(this);
	}
    };
    this.next = () => {
	// listSlips[slipIndex].currentCpt = cpt;
	let flag;
	if((flag = !listSlips[slipIndex].next(this))) {
	    if(slipIndex<listSlips.length-1)
		this.gotoSlipIndex(slipIndex+1);
	}
	this.setCpt();
	//	cpt++;
	// let cpt = this.getCpt();
	// document.querySelector(".cpt-slip").innerText = (toRoman(cpt[0])+"."+(cpt[1]));
	return flag;
    };
    this.nextSlip = () => {
	if(!this.next())
	    this.nextSlip();
    };
    this.skipSlip = (options) => {
	this.gotoSlipIndex(slipIndex+1, options);
	this.setCpt();
    };
    this.previousSlip = () => {
	slipIndex = Math.max(0, slipIndex -1);
	this.gotoSlip(listSlips[slipIndex]);
	this.setCpt();
	// cpt = listSlips[slipIndex].currentCpt;
	// document.querySelector(".cpt-slip").innerText = (cpt);
    };
    this.previous = () => {
	let saveCpt = this.getCurrentSlip().getActionIndex();
	this.refresh();
	if(saveCpt == 0)
	    this.previousSlip();
	else
	    while(this.getCurrentSlip().getActionIndex()<saveCpt-1)
		this.next();
	this.setCpt();
    };
    this.refresh = () => {
	listSlips[slipIndex].refresh();
	this.gotoSlip(listSlips[slipIndex]);
	// cpt = listSlips[slipIndex].initCpt;
	// document.querySelector(".cpt-slip").innerText = (cpt);
	this.setCpt();
    };
    this.start = () => {
	slipIndex = 0;
	this.gotoSlip(listSlips[slipIndex]);
	listSlips[slipIndex].element.style.zIndex = "1";
	listSlips[slipIndex].firstVisit(this);
	// listSlips[slipIndex].initCpt = cpt;
	// listSlips[slipIndex].currentCpt = cpt;
	this.setCpt();
    };
};

let engine = new Engine();
let presentation = new Presentation(engine);
let controller = new Controller(engine, presentation);
presentation.start();

function getAnchor() {
    var currentUrl = document.URL,
	urlParts   = currentUrl.split('#');
		
    return (urlParts.length > 1) ? urlParts[1] : null;
}
let anchor = parseInt(getAnchor());
if(anchor) {
    for(let i=0;i<anchor; i++) {
	presentation.next();
    }
}

