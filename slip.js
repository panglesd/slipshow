let myQueryAll = (root, selector) => {
    if (!root.id)
	root.id = Math.random();
    let allElem = Array.from(root.querySelectorAll(selector));
    let other = Array.from(root.querySelectorAll("#"+root.id+" .slip "+selector));
    return allElem.filter(value => !other.includes(value));
};

function cloneNoSubslip (elem) {
    let newElem = elem.cloneNode(false);
    elem.childNodes.forEach((child) => {
	if(child.classList && child.classList.contains("slip")){
	    let placeholder = document.createElement(child.tagName);
	    placeholder.classList.add("toReplace");
	    newElem.appendChild(placeholder);
	}
	else
	    newElem.appendChild(cloneNoSubslip(child));
    });
    return newElem;
}
function replaceSubslips(clone, subslips) {
    let placeholders = myQueryAll(clone, ".toReplace");
    subslips.forEach((subslip, index) => {
	placeholders[index].replaceWith(subslip);
    });
}



let Engine = function(root) {

    function prepareRoot (rootElem) {
	let container = document.createElement("div");
	container.innerHTML = 
	    '	<div id="open-window">\
	    <div class="format-container">\
	    <div class="rotate-container">\
		<div class="scale-container">\
		    <div class="universe movable" id="universe">\
			<div width="10000" height="10000" class="fog"></div>\
                        <div class="placeHolder"></div>\
		    </div>\
		</div>\
		</div>\
	    </div>\
	</div>\
	<div class="cpt-slip">0</div>';
	rootElem.replaceWith(container);
	container.querySelector(".placeHolder").replaceWith(rootElem);
	rootElem.querySelectorAll(".slip").forEach((slipElem) => {
	    setTimeout(() => {
		var scaleContainer = document.createElement('div');
		var slipContainer = document.createElement('div');
		scaleContainer.classList.add("slip-scale-container");
		slipContainer.classList.add("slip-container");
		let fChild;
		while((fChild = slipElem.firstChild)) {
		    slipContainer.appendChild(fChild);
		}
		scaleContainer.appendChild(slipContainer);
		slipElem.appendChild(scaleContainer);
	    },0);
	});
	rootElem.style.width = "unset";
	rootElem.style.height = "unset";
	document.querySelectorAll(".background-canvas").forEach((elem)=> {elem.addEventListener("click", (ev) => { console.log("vous avez cliquez aux coordonnées : ", ev.layerX, ev.layerY); });});	
    }
    prepareRoot(root);

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
    let slips = universe.querySelectorAll(".slip:not(.root)");
    let browserHeight, openWindowWidth;
    let browserWidth, openWindowHeight;
    this.getOpenWindowHeight = () => openWindowHeight;
    this.getOpenWindowWidth = () => openWindowWidth;

    let winX, winY;
    let currentScale, currentRotate;
    this.getCoord = () => { return {x: winX, y: winY, scale: currentScale};};
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
    this.placeSlip = function(slip) {
	// console.log("debug Previous (slip)", slip);
	// let posX = 0.5;
	// let posY = 0.5;
	// let x=parseFloat(slip.getAttribute("pos-x")), y=parseFloat(slip.getAttribute("pos-y"));
	let scale = parseFloat(slip.getAttribute("scale"));
	// // console.log(slip);
	let slipScaleContainer = slip.querySelector(".slip-scale-container");
	// let rotate = 0;
	scale = isNaN(scale) ? 1 : scale ;
	// x = (isNaN(x) ? posX : x);
	// y = (isNaN(y) ? posY : y);
	// slip.setAttribute("pos-x", x);
	// slip.setAttribute("pos-y", y);
	// slip.setAttribute("scale", scale);
	// slip.setAttribute("rotate", rotate);
	// posX = x + 1;
	// posY = y;
	// slip.style.top = (y*1080 - 1080/2)+"px";
	// slip.style.left = (x*1440 - 1440/2)+"px";
	// if(!slip.classList.contains("permanent"))
	// 	slip.style.zIndex = "-1";
	// slip.style.transformOrigin = "50% 50%";
	slipScaleContainer.style.transform = "scale("+scale+")";
	slip.style.width = (Math.max(slipScaleContainer.offsetWidth, 1440))*scale+"px";
	slip.style.height = (Math.max(slipScaleContainer.offsetHeight, 1080))*scale+"px";	
    };
    this.placeSlips = function () {
	// let posX = 0.5;
	// let posY = 0.5;
	slips.forEach(this.placeSlip);	
    };
    setTimeout(() => {
	this.placeSlips();
    },0);
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
    this.next = () => {
	// return true if and only if the stack changed
	let currentSlide = this.getCurrentSlip();
	let n = currentSlide.next();
	if(n instanceof Slip) {
	    this.gotoSlip(n);
	    this.push(n);
	    this.next();
	    return true;
	}
	else if(!n) {
	    this.pop();
	    let newCurrentSlide = this.getCurrentSlip();
	    this.gotoSlip(newCurrentSlide);
	    // newCurrentSlide.incrIndex();
	    this.next();
	    return true;
	    // console.log(stack);
	}
	return false;
    };
    this.nextSlip = function () {
	// Do this.next() untill the stack change
	while(!this.next()) {}
    };
    this.previous = () => {
	let currentSlide = stack[stack.length - 1];
	// console.log("debug Previous (stack)", stack);
	// console.log("debug Previous (currentSlide)",currentSlide);
	let n = currentSlide.previous();
	// console.log("debug Previous (currentSlide.previous())", n);	
	if(n instanceof Slip) {
	    this.gotoSlip(n);
	    this.push(n);
	    // this.previous();
	}
	else if(!n && stack.length > 1) {
	    this.pop();
	    let newCurrentSlide = this.getCurrentSlip();
	    this.gotoSlip(newCurrentSlide);
	    // newCurrentSlide.incrIndex();
	    this.previous();
	    // console.log(stack);
	}
	// console.log("returned", n);
    };

    this.getCoordinateInUniverse = function (elem) {
	console.log("debug getcoord elem", elem);
	let getCoordInParen = (elem) => {
	    return {x: elem.offsetLeft, y:elem.offsetTop};	    
	};
	let globalScale = 1;
	let parseScale = function(transform) {
	    if (transform == "none")
		return 1;
	    return parseFloat(transform.split("(")[1].split(",")[0]);
	};
	let getCoordIter = (elem) => {
	    let cInParent = getCoordInParen(elem);
	    if(elem.offsetParent.classList.contains("universe"))
	    {
		console.log("universe", cInParent);
		return cInParent;
	    }
	    let cParent = getCoordIter(elem.offsetParent);
	    let style = window.getComputedStyle(elem.offsetParent);
	    // console.log(style);
	    let scale;
	    // console.log("style", style.transform);
	    // if (style.transform == "none")
	    // 	scale = 1;
	    // else
	    // 	scale = parseFloat(style.transform.split("(")[1].split(",")[0]);
	    scale = parseScale(style.transform);
	    // console.log(style.transform);
	    // console.log("scale", scale);
	    // console.log("globalScale", globalScale);
	    globalScale *= scale;
	    // let scale = 1 ; // Has to parse/compute the scale, for now always 1
	    // console.log("at step",  "cParent.x", cParent.x, "cInParen.x", cInParent.x, "scale", scale);
	    return {x:cParent.x+cInParent.x*globalScale, y:cParent.y+cInParent.y*globalScale };
	};
	let c = getCoordIter(elem);
	let style = window.getComputedStyle(elem);
	let scale = parseScale(style.transform);
	globalScale *= scale;
	console.log("getCoord", {x:c.x/1440+0.5, y:c.y/1080+0.5}, "globalScale", globalScale, style.transform, scale);
	let ret = { x: c.x/1440,
		    y: c.y/1080,
		    centerX:c.x/1440+0.5*elem.offsetWidth/1440*globalScale,
		    centerY:c.y/1080+0.5*elem.offsetHeight/1080*globalScale,
		    width: elem.offsetWidth/1440*globalScale,
		    height: elem.offsetHeight/1080*globalScale,
		    scale: globalScale };
	console.log(ret);
	return ret;
	// return {x:c.x/1440+elem*globalScale*scale, y:c.y/1080+0.5*globalScale*scale, scale: globalScale*scale};
	// return {x: this.element.offsetLeft/1440+0.5, y:this.element.offsetTop/1080+0.5};
    };
    this.moveToElement = function(element, options) {
	let coord = this.getCoordinateInUniverse(element);
	let actualSize = {width: element.offsetWidth*coord.scale, height: element.offsetHeight*coord.scale};
	if(options)
	this.moveWindow(coord.x, coord.y, coord.scale, 0, options.delay ? options.delay : 1);
    };
    this.gotoSlip = function(slip, options) {
	console.log("we goto slip");
	options = options ? options : {};
	console.log("options is ", options);
	setTimeout(() => {
	    let coord = slip.findSlipCoordinate();
	    if(typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined")
		this.moveWindow(slip.currentX, slip.currentY, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	    else
		this.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	},0);
    };
    let rootSlip = new Slip(root.id, [], this, {});
    let stack = [rootSlip];

    // Stack Management:
    this.push = function (n) {
	stack.push(n);
	return ;
    };
    this.pop = function () {
	let n = stack.pop();
	if(stack.length == 0)
	    stack.push(n);
	return n;
    };
    this.getCurrentSlip = function () {
	return stack[stack.length -1];
    };
    
    // this.getRootSlip = () => rootSlip;
    this.setRootSlip = (root) => {
	rootSlip = root;
	stack = [rootSlip];
    };
    this.getRootSlip = () => rootSlip;
};

let Controller = function (ng) {
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


function Slip (name, actionL, ng, options) {
    let engine = ng;
    this.getEngine = () => engine;
    this.setEngine = (ng) => engine = ng;
    
    // let presentation = present;
    // this.getPresentation = () => presentation;
    // this.setPresentation = (present) => presentation = present;
    
    this.element = document.querySelector(".slip#"+name);
    console.log(this.element);
    let initialHTML = this.element.outerHTML;
    let clonedElement;
    MathJax.startup.promise.then(() => {
        // console.log('MathJax initial typesetting complete');
	setTimeout(() => {clonedElement = cloneNoSubslip(this.element);},0);
      });
    let innerHTML = this.element.innerHTML;
    this.getCloned = () => clonedElement;
    this.setCloned = (c) => clonedElement = c;
    
    this.findSlipCoordinate = () => { // rename to getCoordInUniverse
	let coord = engine.getCoordinateInUniverse(this.element);
	console.log("debug findslipcoordinate", coord);
	coord.scale *= this.scale;
	coord.y = coord.y + 0.5*coord.scale;
	coord.x = coord.centerX;
	console.log("debug findslipcoordinate", coord);
	return coord;
    };
    
    this.scale = parseFloat(this.element.getAttribute("scale"));
    if(typeof this.scale == "undefined" || isNaN(this.scale)) this.scale = 1;
    this.rotate = parseFloat(this.element.getAttribute("rotate"));
    this.delay = isNaN(parseFloat(this.element.getAttribute("delay"))) ? 0 : (parseFloat(this.element.getAttribute("delay")));
    
    let coord = this.findSlipCoordinate();
    console.log(coord);
    this.x = coord.x;
    this.y = coord.y;
    
    this.queryAll = (quer) => {
	let allElem = Array.from(this.element.querySelectorAll(quer));
	// console.log("allElem", allElem);
	let other = Array.from(this.element.querySelectorAll("#"+name+" .slip "+quer));
	// console.log("other", other, ".slide "+quer);
	return allElem.filter(value => !other.includes(value));
    };
    this.query = (quer) => {
	return this.queryAll(quer)[0];
    };
    let actionList = actionL;
    let actionIndex = -1;
    // let actionIndex=-1;
    this.setActionIndex = (actionI) => actionIndex = actionI;
    this.getActionIndex = () => actionIndex;
    this.setAction = (actionL) => {actionList = actionL;};
    this.setNthAction = (n,action) => {actionList[n] = action;};

    this.doAttributes = () => {
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
	this.queryAll("*[down-at]").forEach((elem) => {
	    let goDownTo = elem.getAttribute("down-at").split(" ").map((str) => parseInt(str));
	    if(goDownTo.includes(actionIndex))
		this.moveDownTo(elem, 1);
	});
	this.queryAll("*[up-at]").forEach((elem) => {
	    let goTo = elem.getAttribute("up-at").split(" ").map((str) => parseInt(str));
	    if(goTo.includes(actionIndex))
		this.moveUpTo(elem, 1);});
	this.queryAll("*[center-at]").forEach((elem) => {
	    let goDownTo = elem.getAttribute("center-at").split(" ").map((str) => parseInt(str));
	    if(goDownTo.includes(actionIndex))
		this.moveCenterTo(elem, 1);});	
    };

    this.incrIndex = () => {
	console.log("incrIndex");
	actionIndex = actionIndex+1;
	this.doAttributes();
	// this.hideAndShow();
    };
    
    this.next = function () {
	// if(actionIndex == -1) {
	//     this.incrIndex();
	//     this.firstVisit();
	//     return true;
	// }
	if(actionIndex >= this.getMaxNext())
	    return false;
	this.incrIndex();
	// console.log(actionList);
	if(typeof actionList[actionIndex] == "function") {
	    // console.log("here");
	    actionList[actionIndex](this);
	}
	if(actionList[actionIndex] instanceof Slip){
	    // if(!actionList[actionIndex].next()) {
	    // 	// actionIndex += 1;
	    // 	this.incrIndex();
	    // }
	    return actionList[actionIndex];
	}
	// else
	//     this.incrIndex();
	// }, 0);
	// this.incrIndex();
	return true;
    };
    this.previous = () => {
	let savedActionIndex = this.getActionIndex();
	this.doRefresh();
	if(savedActionIndex == -1)
	    // this.previousSlip();
	    return false;
 	let toReturn;
	while(this.getActionIndex()<savedActionIndex-1)
	    toReturn = this.next();
	return toReturn;
	// this.setCpt();
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
	this.doAttributes();
	if(options.init)
	    options.init(this);
    };
    this.whenLeaving = () => {
	if(options.whenLeaving)
	    options.whenLeaving(this);
    };
	
    this.refresh = () => {
	if(actionList[actionIndex] instanceof Slip)
	    actionList[actionIndex].refresh();
	else
	    this.doRefresh();
    };
    this.doRefresh = () => {
	this.setActionIndex(-1);
	// console.log(this.element);
	// this.element.outerHTML = initialHTML;
	// this.element.innerHTML = innerHTML;
	let subSlipList = myQueryAll(this.element, ".slip");;
	// console.log("debug refresh,  subsliplist", subSlipList);
	let clone = clonedElement.cloneNode(true);
	replaceSubslips(clone, subSlipList);
	this.element.replaceWith(clone);
	this.element = clone;
	// this.element = clonedElement;
	// this.element.replaceWith(clonedElement);
	// this.element = clonedElement;
	// clonedElement = cloneNoSubslip(this.element);
	// engine.placeSlip(this.element);
	// if(typeof hljs != "undefined")
	//     document.querySelectorAll('pre code').forEach((block) => {
	// 	hljs.highlightBlock(block);
	//     });
	// if(MathJax && typeof MathJax.typeset == "function")
	//     MathJax.typeset();
	// else if (MathJax && MathJax.Hub && typeof MathJax.Hub.Typeset == "function")
	//     MathJax.Hub.Typeset();
	this.init();
	this.firstVisit();
	// console.log("ai", actionIndex);
    };
    this.init(this, engine);
    this.moveUpTo = (selector, delay,  offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0.0125;
	    let coord = this.findSlipCoordinate();
	    let d = ((elem.offsetTop)/1080-offset)*coord.scale;
	    this.currentX = coord.x;
	    this.currentY = coord.y+d;
	    engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	},0);
    };
    this.moveDownTo = (selector, delay, offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0.0125;
	    let coord = this.findSlipCoordinate();
	    let d = ((elem.offsetTop+elem.offsetHeight)/1080 - 1 + offset)*coord.scale;
	    this.currentX = coord.x;
	    this.currentY = coord.y+d;
	    engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	},0);
    };
    this.moveCenterTo = (selector, delay, offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0;
	    let coord = this.findSlipCoordinate();
	    let d = ((elem.offsetTop+elem.offsetHeight/2)/1080-1/2+offset)*coord.scale;
	    this.currentX = coord.x;
	    this.currentY = coord.y+d;
	    engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
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
	    let coord = slip.findSlipCoordinate();
	    // engine.moveWindow(coord.x, coord.y, slip.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	    if(typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined")
		engine.moveWindow(slip.currentX, slip.currentY, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	    else
		engine.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
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
/*
  Tasks :
  - create RootSlip
  - remove Presentation class
  - change Slip class

  -> Engine
  toRoman, DONE
  gotoSlip,
  nextSlip,
  skipSlip,
  previousSlip,
  next,
  previous,
  refresh,
  listSlips,
  slipIndex -> slipStack,
  getSlips,
  setSlips,
  getCurrentSlip,
  start,  

  -> Slip
  getCpt, 
  setCpt,
  gotoSlip -> gotoSubSlip
  ??  gotoSlipIndex -> gotoSubSlipIndex,

  -> Trash
  getEngine,
  setEngine,



*/

// let engine = new Engine();
// // let presentation = new Presentation(engine);
// let controller = new Controller(engine, presentation);
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

