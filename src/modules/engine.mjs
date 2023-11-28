import { myQueryAll } from './util';
import Controller from './controller';
import Slip from './slip';

export default function (root) {
    function prepareRoot (rootElem) {
	let container = document.createElement("div");
	container.innerHTML = 
	    `	
	<div class="toc-slip" style="display:none;"></div>
        <div id="open-window">
	  <div class="cpt-slip">0</div>
	  <div class="slip-writing-toolbar">
              <div class="slip-toolbar-tool no-tool">
                  <div class="slip-toolbar-pen">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M33.87 8.32L28 2.42a2.07 2.07 0 0 0-2.92 0L4.27 23.2l-1.9 8.2a2.06 2.06 0 0 0 2 2.5a2.14 2.14 0 0 0 .43 0l8.29-1.9l20.78-20.76a2.07 2.07 0 0 0 0-2.92zM12.09 30.2l-7.77 1.63l1.77-7.62L21.66 8.7l6 6zM29 13.25l-6-6l3.48-3.46l5.9 6z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
                  </div>
                  <div class="slip-toolbar-highlighter">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="25" height="25" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M15.82 26.06a1 1 0 0 1-.71-.29l-6.44-6.44a1 1 0 0 1-.29-.71a1 1 0 0 1 .29-.71L23 3.54a5.55 5.55 0 1 1 7.85 7.86L16.53 25.77a1 1 0 0 1-.71.29zm-5-7.44l5 5L29.48 10a3.54 3.54 0 0 0 0-5a3.63 3.63 0 0 0-5 0z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><path d="M10.38 28.28a1 1 0 0 1-.71-.28l-3.22-3.23a1 1 0 0 1-.22-1.09l2.22-5.44a1 1 0 0 1 1.63-.33l6.45 6.44A1 1 0 0 1 16.2 26l-5.44 2.22a1.33 1.33 0 0 1-.38.06zm-2.05-4.46l2.29 2.28l3.43-1.4l-4.31-4.31z" class="clr-i-outline clr-i-outline-path-2" fill="#000000"/><path d="M8.94 30h-5a1 1 0 0 1-.84-1.55l3.22-4.94a1 1 0 0 1 1.55-.16l3.21 3.22a1 1 0 0 1 .06 1.35L9.7 29.64a1 1 0 0 1-.76.36zm-3.16-2h2.69l.53-.66l-1.7-1.7z" class="clr-i-outline clr-i-outline-path-3" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
                  <div class="slip-toolbar-eraser">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path d="M35.62 12a2.82 2.82 0 0 0-.84-2l-7.29-7.35a2.9 2.9 0 0 0-4 0L2.83 23.28a2.84 2.84 0 0 0 0 4L7.53 32H3a1 1 0 0 0 0 2h25a1 1 0 0 0 0-2H16.74l18-18a2.82 2.82 0 0 0 .88-2zM13.91 32h-3.55l-6.11-6.11a.84.84 0 0 1 0-1.19l5.51-5.52l8.49 8.48zm19.46-19.46L19.66 26.25l-8.48-8.49l13.7-13.7a.86.86 0 0 1 1.19 0l7.3 7.29a.86.86 0 0 1 .25.6a.82.82 0 0 1-.25.59z" class="clr-i-outline clr-i-outline-path-1" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
                  <div class="slip-toolbar-cursor">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" focusable="false" width="20" height="20" style="-ms-transform: rotate(360deg); -webkit-transform: rotate(360deg); transform: rotate(360deg);" preserveAspectRatio="xMidYMid meet" viewBox="0 0 36 36"><path class="clr-i-outline clr-i-outline-path-1" d="M14.58 32.31a1 1 0 0 1-.94-.65L4 5.65a1 1 0 0 1 1.25-1.28l26 9.68a1 1 0 0 1-.05 1.89l-8.36 2.57l8.3 8.3a1 1 0 0 1 0 1.41l-3.26 3.26a1 1 0 0 1-.71.29a1 1 0 0 1-.71-.29l-8.33-8.33l-2.6 8.45a1 1 0 0 1-.93.71zm3.09-12a1 1 0 0 1 .71.29l8.79 8.79L29 27.51l-8.76-8.76a1 1 0 0 1 .41-1.66l7.13-2.2L6.6 7l7.89 21.2l2.22-7.2a1 1 0 0 1 .71-.68z" fill="#000000"/><rect x="0" y="0" width="36" height="36" fill="rgba(0, 0, 0, 0)" /></svg>
</div>
              </div>
              <div class="slip-toolbar-color">
                  <div class="slip-toolbar-black"></div>
                  <div class="slip-toolbar-blue"></div>
                  <div class="slip-toolbar-red"></div>
                  <div class="slip-toolbar-green"></div>
                  <div class="slip-toolbar-yellow"></div>
              </div>

              <div class="slip-toolbar-width">
                  <div class="slip-toolbar-small"><div></div></div>
                  <div class="slip-toolbar-medium"><div></div></div>
                  <div class="slip-toolbar-large"><div></div></div>
              </div>
              <div class="slip-toolbar-control">
                  <!-- <div class="slip-toolbar-stop">✓</div> -->
                  <div class="slip-toolbar-clear">✗</div>
              </div>
          </div>
	  <div class="format-container">
	    <div class="rotate-container">
		<div class="scale-container">
		    <div class="universe movable" id="universe">
			<div width="10000" height="10000" class="fog"></div>
                        <div class="placeHolder"></div>
		    </div>
		</div>
              </div>
	    </div>
	</div>`;
	rootElem.replaceWith(container);
	container.querySelector(".placeHolder").replaceWith(rootElem);
	rootElem.querySelectorAll("slip-slip").forEach((slipElem) => {
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
		setTimeout(() => {
		    // let canvas = document.createElement('canvas');
		    // canvas.height = slipContainer.offsetHeight;
		    // canvas.width = slipContainer.offsetWidth;
		    // canvas.classList.add("sketchpad");
		    // canvas.style.opacity = "1";
		    // slipContainer.appendChild(canvas);
		    // let sketchpad = new Atrament(canvas);
		    // sketchpad.smoothing = 0.2;
		},0);
	    },0);
	});
	rootElem.style.width = "unset";
	rootElem.style.height = "unset";
	// document.querySelectorAll(".background-canvas").forEach((elem)=> {elem.addEventListener("click", (ev) => { console.log("vous avez cliquez aux coordonnées : ", ev.layerX, ev.layerY); });});	
    }
    if (typeof(root) == "string") {
	if(root[0] != "#")
	    root = "#"+root;
	root = document.querySelector(root);
    }
    else if (typeof(root) == "undefined")
	root = document.querySelector("slip-slipshow");
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
    let slips = universe.querySelectorAll("slip-slip:not(slip-slipshow)");
    let browserHeight, openWindowWidth;
    let browserWidth, openWindowHeight;
    this.getOpenWindowHeight = () => openWindowHeight;
    this.getOpenWindowWidth = () => openWindowWidth;

    let winX, winY;
    let currentScale, currentRotate;
    this.getCoord = () => { return {x: winX, y: winY, scale: currentScale};};
    let doNotMove = false;
    this.setDoNotMove = m => doNotMove = m;
    this.getDoNotMove = m => doNotMove;
    let alwaysMoveFast = false;
    this.setAlwaysMoveFast = m => {setTimeout(() => {alwaysMoveFast = m}, 0)};
    this.getAlwaysMoveFast = m => alwaysMoveFast;
    this.moveWindow = function (x, y, scale, rotate, delay) {
	if(this.getDoNotMove()) {
	    return;
	}
	let my_delay = delay;
	if(this.getAlwaysMoveFast()) {
	    my_delay = "0";
	}
	currentScale = scale;
	currentRotate = rotate;
	winX = x ;
	winY = y;
	setTimeout(() => {
	    document.querySelector(".scale-container").style.transitionDuration = my_delay+"s";
	    document.querySelector(".rotate-container").style.transitionDuration = my_delay+"s";
	    universe.style.transitionDuration = my_delay+"s, "+my_delay+ "s"; 
	    setTimeout(() => {
		universe.style.left = -(x*1440 - 1440/2)+"px";
		universe.style.top = -(y*1080 - 1080/2)+"px";
		document.querySelector(".scale-container").style.transform = "scale("+(1/scale)+")";
		document.querySelector(".rotate-container").style.transform = "rotate("+(rotate)+"deg)";
	    },0);
	},0);
	return;
    };
    this.moveWindowRelative = function(dx, dy, dscale, drotate, delay) {
	this.moveWindow(winX+dx, winY+dy, currentScale+dscale, currentRotate+drotate, delay);
    };
    this.placeSlip = function(slip) {
	let scale = parseFloat(slip.getAttribute("scale"));
	let slipScaleContainer = slip.querySelector(".slip-scale-container");
	scale = isNaN(scale) ? 1 : scale ;
	slipScaleContainer.style.transform = "scale("+scale+")";
	const resizeObserver = new ResizeObserver(entries => {
	    slip.style.width = (Math.max(slipScaleContainer.offsetWidth, 1440))*scale+"px";
	    slip.style.height = (Math.max(slipScaleContainer.offsetHeight, 1080))*scale+"px";
	});

	resizeObserver.observe(slipScaleContainer);
    };
    this.placeSlips = function () {
	let depth = function (elem) {
	    let subslips = myQueryAll(elem, "slip-slip");
	    return 1+subslips.map(depth).reduce((a,b) => Math.max(a,b),0);
	};
	let rootDepth = depth(document.body);
	for(let i= 0; i<rootDepth; i++)
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
    function counterToString(num, depth) {
	if(depth == 1 || depth > 3)
	    return num.toString();
	let result = '';
	let decimal = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
	let roman;
	if(depth == 0)
	    roman = ["M", "CM","D","CD","C", "XC", "L", "XL", "X","IX","V","IV","I"];
	else
	    roman = ["m", "cm","d","cd","c", "xc", "l", "xl", "x","ix","v","iv","i"];
	for (var i = 0;i<=decimal.length;i++) {
	    while (num%decimal[i] < num) {     
		result += roman[i];
		num -= decimal[i];
	    }
	}
	return result;
    }
    this.countersToString = (counterList) => {
	let res = '';
	res += counterToString(counterList[0]+1, 0);
	for(let i = 1; i < counterList.length; i++)
	    res += "." + counterToString(counterList[i]+1, i);
	return res;	
    };
    this.updateCounter = function () {
	let counters = stack.map((slip) => slip.getActionIndex());
	let hash = counters.join(',');
	if(window.parent !== window){
	    window.parent.postMessage(hash, "*");
	}
	else
 	    window.history.replaceState(null, null, '#' + hash);
	document.querySelector(".cpt-slip").innerHTML = this.countersToString(counters);	
    };
    this.enter = (n) => {
	this.gotoSlip(n);
	this.push(n);
	this.next();
    };
    this.next = () => {
	if(document.querySelector(".toc-slip").innerHTML == "")
	    this.showToC();
	// return true if and only if the stack changed
	let currentSlip = this.getCurrentSlip();
	let n = currentSlip.next();
	this.updateCounter();
	if(n instanceof Slip) {
	    this.enter(n);
	    // this.gotoSlip(n);
	    // this.push(n);
	    // this.next();
	    // this.showToC();
	    return true;
	}
	else if(!n) {
	    this.pop();
	    let newCurrentSlip = this.getCurrentSlip();
	    if(newCurrentSlip.nextStageNeedGoto())
		this.gotoSlip(newCurrentSlip);
	    if(stack.length > 1 || newCurrentSlip.getActionIndex() < newCurrentSlip.getMaxNext())
		this.next();
	    else
		this.gotoSlip(newCurrentSlip);
	    return true;
	}
	return false;
    };
    this.nextSlip = function () {
	// Do this.next() untill the stack change
	while(!this.next()) {}
    };
    this.previous = (options) => {
	let currentSlip = this.getCurrentSlip();
	// setDoNotMove(true);
	// let stage = currentSlip.previous2();
	// setDoNotMove(false);
	let n = currentSlip.previous();
	// if(stage == "")
	if(n instanceof Slip) {
	    while(n.getCurrentSubSlip() instanceof Slip) {
		this.push(n);
		n = n.getCurrentSubSlip();
	    }
	    this.push(n);
	    
	    this.gotoSlip(n, options);
	    // this.gotoSlip(n, {delay: currentSlip.delay});
		
	    // this.showToC();
	    this.updateCounter();
	    return true;
	}
	else if(!n) {
	    this.pop();
	    let newCurrentSlip = this.getCurrentSlip();
	    // newCurrentSlip.incrIndex();
	    
	    if(stack.length > 1 || newCurrentSlip.getActionIndex() > -1)
		this.previous({delay: (currentSlip.currentDelay ? currentSlip.currentDelay : currentSlip.delay )});
	    else {
		this.gotoSlip(newCurrentSlip, options);
	    }
		// this.gotoSlip(newCurrentSlip, {delay: currentSlip.delay});
	    // this.showToC();
	    this.updateCounter();
	    return true;
	} else if(options){
	    setTimeout(() => {
		this.gotoSlip(currentSlip, options);
	    },0);
	}
	// this.showToC();
	setTimeout(() => {
	    this.gotoSlip(currentSlip, options);
	},0);
	this.updateCounter();
	return false;
    };
    this.previousSlip = function () {
	// Do this.previous() untill the stack change
	while(!this.previous()) {}
    };

    this.getCoordinateInUniverse = function (elem) {
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
	    if(!elem.offsetParent)
		return { x: 0,
			 y: 0,
			 centerX: 0,
			 centerY: 0,
			 width: 0,
			 height: 0,
			 scale: 0 };
	    if(elem.offsetParent.classList.contains("universe"))
	    {
		return cInParent;
	    }
	    let cParent = getCoordIter(elem.offsetParent);
	    let style = window.getComputedStyle(elem.offsetParent);
	    let scale;
	    // if (style.transform == "none")
	    // 	scale = 1;
	    // else
	    // 	scale = parseFloat(style.transform.split("(")[1].split(",")[0]);
	    scale = parseScale(style.transform);
	    globalScale *= scale;
	    // let scale = 1 ; // Has to parse/compute the scale, for now always 1
	    return {x:cParent.x+cInParent.x*globalScale, y:cParent.y+cInParent.y*globalScale };
	};
	let c = getCoordIter(elem);
	let style = window.getComputedStyle(elem);
	let scale = parseScale(style.transform);
	globalScale *= scale;
	let ret = { x: c.x/1440,
		    y: c.y/1080,
		    centerX:c.x/1440+0.5*elem.offsetWidth/1440*globalScale,
		    centerY:c.y/1080+0.5*elem.offsetHeight/1080*globalScale,
		    width: elem.offsetWidth/1440*globalScale,
		    height: elem.offsetHeight/1080*globalScale,
		    scale: globalScale };
	return ret;
	// return {x:c.x/1440+elem*globalScale*scale, y:c.y/1080+0.5*globalScale*scale, scale: globalScale*scale};
	// return {x: this.element.offsetLeft/1440+0.5, y:this.element.offsetTop/1080+0.5};
    };
    this.moveToElement = function(element, options) {
	let coord = this.getCoordinateInUniverse(element);
	let actualSize = {width: element.offsetWidth*coord.scale, height: element.offsetHeight*coord.scale};
	if(options)
	    this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height)// coord.scale
			    , 0, options.delay ? options.delay : 1);
    };
    this.gotoSlip = function(slip, options) {
	// console.log("going to slip", slip, slip.element);
	options = options ? options : {};
	if(slip.element.tagName == "SLIP-SLIP")
	{
	     setTimeout(() => {
		let coord = slip.findSlipCoordinate();
		if(typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined" && typeof slip.currentScale != "undefined") {
		    this.moveWindow(slip.currentX, slip.currentY, slip.currentScale, slip.rotate, typeof(options.delay)!="undefined" ? options.delay : (typeof(slip.currentDelay)!="undefined" ? slip.currentDelay : slip.delay));
		} else {
		    slip.currentX = coord.x; slip.currentY = coord.y; slip.currentDelay = slip.delay;
		    this.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, typeof(options.delay)!="undefined" ? options.delay : (typeof(slip.currentDelay)!="undefined" ? slip.currentDelay : slip.delay));
		}
	     },0);
	}
	else {
	     setTimeout(() => {
		let coord = this.getCoordinateInUniverse(slip.element);
		 this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height), 0, typeof(options.delay)!="undefined" ? options.delay : slip.delay);
	     },0);
	}
    };
    let rootSlip = new Slip(root, "Presentation", [], this, {});
    let stack = [rootSlip];

    // Stack Management:
    this.push = function (n) {
	this.getToC().querySelectorAll(".toc-slip .active-slip").forEach(elem => elem.classList.remove("active-slip"));
	if(n.tocElem)
	    n.tocElem.classList.add("active-slip");
	n.element.classList.add("active-true-slip");
	if(stack.length>0)
	    stack[stack.length-1].element.classList.remove("active-true-slip");
	stack.push(n);
	return ;
    };
    this.pop = function () {
	this.getToC().querySelectorAll(".toc-slip .active-slip").forEach(elem => elem.classList.remove("active-slip"));
	let n = stack.pop();
	n.element.classList.remove("active-true-slip");
	if(stack.length == 0)
	    stack.push(n);
	stack[stack.length-1].element.classList.add("active-true-slip");
	if(stack[stack.length -1].tocElem)
	    stack[stack.length -1].tocElem.classList.add("active-slip");
	return n;
    };
    this.getCurrentSlip = function () {
	return stack[stack.length -1];
    };
    this.getSlipTree = function (slip) {
	slip = slip || rootSlip;
	if(slip instanceof Slip) 
	    return {name: slip.name, slip: slip, subslips: slip.getActionList().map((e) => this.getSlipTree(e))};
	return {function: true};
    };

    this.goToState = function(state) {
	let iter = (state) => {
	    if(state.length == 0)
		return;
	    iter(state[0]);
	    while(state[1].getActionIndex()<state[2])
		this.next();
	};
	stack = [rootSlip];
	rootSlip.refreshAll();
	iter(state);
	this.gotoSlip(state[1]);
    };
    let toc;
    this.getToC = function() {
	if (toc)
	    return toc;
	toc = document.querySelector(".toc-slip");
	return toc;
    };
    this.showToC = function () {
	let toc = document.querySelector(".toc-slip");
	// let innerHTML = "";
	let globalElem = document.createElement("div");
	let tree = this.getSlipTree();
	// let before = true;
	let displayTree = (tree, stackWithNumbers) => {
	    let containerElement = document.createElement("div");
	    let nameElement = document.createElement("div");
	    // if(before)
	    // 	nameElement.style.color = "blue";
	    // else
	    // 	nameElement.style.color = "yellow";
	    // if(tree.slip == this.getCurrentSlip()) {
	    // 	nameElement.style.color = "red";
	    // 	before = false;
	    // }
		
	    nameElement.innerText = tree.slip.fullName; //? tree.slip.fullName : tree.slip.name ; //+ " (" + (tree.slip.getActionIndex()+1) + "/" + (tree.slip.getMaxNext()+1) + ")";
	    containerElement.appendChild(nameElement);
	    // innerHTML += "<div>"+tree.name+"</div>";
	    if(tree.subslips.length > 0) {
		let ulElement = document.createElement("ul");
		// innerHTML += "<ul>";
		tree.subslips.forEach((subtree, index) => {
		    let newStackWithNumbers = [stackWithNumbers, tree.slip, index];
		    let liElement = document.createElement("li");
		    // innerHTML += "<li>";
		    if(subtree.function) {
			let toCounter = (c) => {
			    if(c.length == 0)
				return [];
			    return toCounter(c[0]).concat([c[2]]);
			};
			liElement.innerText = this.countersToString(toCounter(newStackWithNumbers));
			//			liElement.innerText = ""+(index+1);
			liElement.classList.add("toc-function");
		    } else
			liElement.appendChild(displayTree(subtree, newStackWithNumbers));
		    liElement.addEventListener("click", (ev) => {
		    	if(ev.target == liElement) {
		    	    this.goToState(newStackWithNumbers);
		    	}
		    });
		    ulElement.appendChild(liElement);
		    
		    // innerHTML += "</li>";
		});
		containerElement.appendChild(ulElement);
		tree.slip.setTocElem(containerElement);
		// innerHTML += "</ul>";
	    }
	    return containerElement;
	};
	toc.innerHTML = "";
	// toc.innerHTML = innerHTML;
	toc.appendChild(displayTree(tree, []));
    };

    // ******************************
    // Function for writing and highlighting
    // ******************************

    this.getTool = () => {
	return this.getCurrentSlip().getTool();
    };
    this.setTool = (tool) => {
	this.getCurrentSlip().setTool(tool);
	this.updateToolClasses();
    };
    this.getColor = () => {
	return this.getCurrentSlip().getColor();
    };
    this.setColor = (color) => {
	this.getCurrentSlip().setColor(color);
	this.updateToolClasses();
    };
    this.setLineWidth = (lw) => {
	this.getCurrentSlip().setLineWidth(lw);
	this.updateToolClasses();
    };
    this.getLineWidth = () => {
	return this.getCurrentSlip().getLineWidth();
    };
    this.reloadCanvas = () => {
	this.getCurrentSlip().reloadCanvas();
    };
    let that = this;
    function addToolEvents() {
	document.querySelector(".slip-toolbar-pen").addEventListener("click", function(ev) {
	    that.setTool("drawing");
	});
	document.querySelector(".slip-toolbar-cursor").addEventListener("click", function(ev) {
	    that.setTool("no-tool");
	});
	document.querySelector(".slip-toolbar-eraser").addEventListener("click", function(ev) {
	    switch(that.getTool()) {
	    case "drawing-erase":
		that.setTool("drawing");
		break;
	    case "highlighting":
		that.setTool("highlighting-erase");
		break;
	    case "highlighting-erase":
		that.setTool("highlighting");
		break;
	    case "no-tool":
		that.setTool("no-tool");
		break;
	    case "drawing":
		that.setTool("drawing-erase");
		break;
	    }
	});
	document.querySelector(".slip-toolbar-highlighter").addEventListener("click", function(ev) {
	    that.setTool("highlighting");
	});
	document.querySelector(".slip-toolbar-black").addEventListener("click", function(ev) {
	    that.setColor("black");
	});
	document.querySelector(".slip-toolbar-blue").addEventListener("click", function(ev) {
	    that.setColor("blue");
	});
	document.querySelector(".slip-toolbar-red").addEventListener("click", function(ev) {
	    that.setColor("red");
	});
	document.querySelector(".slip-toolbar-green").addEventListener("click", function(ev) {
	    that.setColor("green");
	});
	document.querySelector(".slip-toolbar-yellow").addEventListener("click", function(ev) {
	    that.setColor("yellow");
	});
	document.querySelector(".slip-toolbar-small").addEventListener("click", function(ev) {
	    that.setLineWidth("small");
	});
	document.querySelector(".slip-toolbar-medium").addEventListener("click", function(ev) {
	    that.setLineWidth("medium");
	});
	document.querySelector(".slip-toolbar-large").addEventListener("click", function(ev) {
	    that.setLineWidth("large");
	});
	document.querySelector(".slip-toolbar-clear").addEventListener("click", function(ev) {
	    that.setTool("clear-all");
	});
    }
    this.updateToolClasses = () => {
	document.querySelector(".slip-toolbar-tool").classList.remove("drawing","highlighting", "drawing-erase", "highlighting-erase", "no-tool");
	if(this.getTool()=="no-tool" || this.getTool()=="cursor")
	    document.querySelector(".slip-writing-toolbar").classList.remove("active");
	else
	    document.querySelector(".slip-writing-toolbar").classList.add("active");
	document.querySelector(".slip-toolbar-tool").classList.add(this.getTool());
	document.querySelector(".slip-toolbar-color").classList.remove("black","blue", "red", "green", "yellow");
	document.querySelector(".slip-toolbar-color").classList.add(this.getColor());
	document.querySelector(".slip-toolbar-width").classList.remove("small","medium", "large");
	document.querySelector(".slip-toolbar-width").classList.add(this.getLineWidth());
    };
    setTimeout(addToolEvents, 0);

    // ******************************
    // 
    // ******************************


    
    // this.getRootSlip = () => rootSlip;
    this.setRootSlip = (root) => {
	rootSlip = root;
	stack = [rootSlip];
    };
    this.getRootSlip = () => rootSlip;
    this.start = () => {
	stack = [rootSlip];
	if(window.location.hash) {

	    let target_stack = window.location.hash.slice(1).split(",").map(x => parseInt(x));
	    this.setAlwaysMoveFast(true);
	    console.log("alwaysMoveFast", this.getAlwaysMoveFast())
	    let unfinished = -1;
	    let continue_please = 0;
	    let stop_now = 1;
	    let not_arrived = function () {
		let counters = stack.map((slip) => slip.getActionIndex());
		let return_value = unfinished;
		target_stack.forEach((target, i) => {
		    if (return_value != unfinished)
			return;
		    if (target < counters[i])
			return_value = stop_now;
		    if (target > counters[i])
			return_value = continue_please;
		});
		return return_value;
	    }
	    while(not_arrived() == continue_please)
		this.next();
	    this.setAlwaysMoveFast(false);
	}
	else
	    this.next();
	return this;
    };
    this.restart = () => {
	stack = [rootSlip];
	rootSlip.refreshAll();
	this.next();
    };
    let controller = new Controller(this);
    this.getController = () => controller;
    // if(window !== window.parent)
    window.addEventListener("message", (event) => {
	console.log(event);
	    this.restart();
	    let target_stack = event.data.split(",").map(x => parseInt(x));
	    this.setAlwaysMoveFast(true);
	    console.log("alwaysMoveFast", this.getAlwaysMoveFast())
	    let unfinished = -1;
	    let continue_please = 0;
	    let stop_now = 1;
	    let not_arrived = function () {
		let counters = stack.map((slip) => slip.getActionIndex());
		let return_value = unfinished;
		target_stack.forEach((target, i) => {
		    if (return_value != unfinished)
			return;
		    if (target < counters[i])
			return_value = stop_now;
		    if (target > counters[i])
			return_value = continue_please;
		});
		return return_value;
	    }
	    while(not_arrived() == continue_please)
		this.next();
	    this.setAlwaysMoveFast(false);

	});
};
