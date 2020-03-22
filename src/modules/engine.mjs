import { myQueryAll } from './util'

export default function (root) {
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
	<div class="cpt-slip">0</div>\
	<div class="toc-slip" style="display:none;"></div>';
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
    let doNotMove = false;
    this.setDoNotMove = m => doNotMove = m;
    this.getDoNotMove = m => doNotMove;
    this.moveWindow = function (x, y, scale, rotate, delay) {
	if(this.getDoNotMove()) {
	    console.log("we cannot move");
	    console.log("previous is ca we cannot move !");
	    return;
	}
	console.log("previous is ca getDoNotMove !", x,y,scale, rotate, delay, this.getDoNotMove());
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
	let depth = function (elem) {
	    console.log("debug depth (elem)", elem);
	    let subslips = myQueryAll(elem, ".slip");
	    console.log("debug depth (subslips)", elem);
	    return 1+subslips.map(depth).reduce((a,b) => Math.max(a,b),0);
	};
	let rootDepth = depth(document.body);
	console.log("debug", rootDepth);
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
	document.querySelector(".cpt-slip").innerHTML = this.countersToString(counters);	
    };
    this.next = () => {
	if(document.querySelector(".toc-slip").innerHTML == "")
	    this.showToC();
	// return true if and only if the stack changed
	let currentSlide = this.getCurrentSlip();
	let n = currentSlide.next();
	this.updateCounter();
	if(n instanceof Slip) {
	    this.gotoSlip(n);
	    this.push(n);
	    this.next();
	    // this.showToC();
	    return true;
	}
	else if(!n) {
	    this.pop();
	    let newCurrentSlip = this.getCurrentSlip();
	    if(newCurrentSlip.nextStageNeedGoto())
		this.gotoSlip(newCurrentSlip);
	    // newCurrentSlip.incrIndex();
	    if(stack.length > 1 || newCurrentSlip.getActionIndex() < newCurrentSlip.getMaxNext())
		this.next();
	    else
		this.gotoSlip(newCurrentSlip);
	    // this.showToC();
	    return true;
	    // console.log(stack);
	}
	// this.showToC();
	return false;
    };
    this.nextSlip = function () {
	// Do this.next() untill the stack change
	while(!this.next()) {}
    };
    this.previous = (options) => {
	console.log("previous is called with option", options);
	let currentSlip = this.getCurrentSlip();
	// setDoNotMove(true);
	// let stage = currentSlip.previous2();
	// setDoNotMove(false);
	let n = currentSlip.previous();
	// if(stage == "")
	console.log("debug previous (currentSlip, n)", currentSlip, n);
	if(n instanceof Slip) {
	    while(n.getCurrentSubSlip() instanceof Slip) {
		this.push(n);
		n = n.getCurrentSubSlip();
	    }
	    this.push(n);
	    console.log("previous is ca GOTOSLIP FROM 1", options);
	    
	    this.gotoSlip(n, options);
	    // this.gotoSlip(n, {delay: currentSlip.delay});
		
	    // this.showToC();
	    this.updateCounter();
	    return true;
	}
	else if(!n) {
	    this.pop();
	    let newCurrentSlide = this.getCurrentSlip();
	    // newCurrentSlide.incrIndex();
	    console.log("previous is ca currentDelay, delay", currentSlip.currentDelay , currentSlip.delay);
	    
	    if(stack.length > 1 || newCurrentSlide.getActionIndex() > -1)
		this.previous({delay: (currentSlip.currentDelay ? currentSlip.currentDelay : currentSlip.delay )});
	    else {
		this.gotoSlip(newCurrentSlide, options);
		console.log("previous is ca GOTOSLIP FROM 2", options);
	    }
		// this.gotoSlip(newCurrentSlide, {delay: currentSlip.delay});
	    // console.log(stack);
	    // this.showToC();
	    this.updateCounter();
	    return true;
	} else if(options){
	    setTimeout(() => {
		this.gotoSlip(currentSlip, options);
	    },0);
	}
	// this.showToC();
	this.updateCounter();
	return false;
	// console.log("returned", n);
    };
    this.previousSlip = function () {
	// Do this.previous() untill the stack change
	while(!this.previous()) {}
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
	    console.log("debug getcoorditer elem", elem);
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
	    this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height)// coord.scale
			    , 0, options.delay ? options.delay : 1);
    };
    this.gotoSlip = function(slip, options) {
	console.log("previous is ca goto slip", options, slip.element, this.getDoNotMove());
	console.log("we goto slip", slip.element, this.getDoNotMove());
	options = options ? options : {};
	console.log("options is ", options);
	if(slip.element.classList.contains("slip"))
	{
	     setTimeout(() => {
		let coord = slip.findSlipCoordinate();
		if(typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined") {
		    console.log("previous is ca ORIGIN 1", slip.currentX, slip.currentY, this.getDoNotMove(), options);
		    this.moveWindow(slip.currentX, slip.currentY, coord.scale, slip.rotate, typeof(options.delay)!="undefined" ? options.delay : (typeof(slip.currentDelay)!="undefined" ? slip.currentDelay : slip.delay));
		} else {
		    slip.currentX = coord.x; slip.currentY = coord.y; slip.currentDelay = slip.delay;
		    console.log("previous is ca ORIGIN 2", coord.x, coord.y, this.getDoNotMove());
		    this.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, typeof(options.delay)!="undefined" ? options.delay : (typeof(slip.currentDelay)!="undefined" ? slip.currentDelay : slip.delay));
		}
	     },0);
	}
	else {
	     setTimeout(() => {
		console.log("debug slip element", slip.element);
		let coord = this.getCoordinateInUniverse(slip.element);
		 this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height), 0, typeof(options.delay)!="undefined" ? options.delay : slip.delay);
	     },0);
	}
    };
    let rootSlip = new Slip(root.id, "Presentation", [], this, {});
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

    this.showToC = function () {
	console.log("debug showtoc");
	let toc = document.querySelector(".toc-slip");
	// let innerHTML = "";
	let globalElem = document.createElement("div");
	let tree = this.getSlipTree();
	// let before = true;
	let displayTree = (tree, stackWithNumbers) => {
	    console.log("debug treee", tree);
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
		
	    nameElement.innerText = tree.slip.fullName ? tree.slip.fullName : tree.slip.name ; //+ " (" + (tree.slip.getActionIndex()+1) + "/" + (tree.slip.getMaxNext()+1) + ")";
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
		    	    console.log("newstack", newStackWithNumbers);
		    	}
		    });
		    ulElement.appendChild(liElement);
		    
		    // innerHTML += "</li>";
		});
		containerElement.appendChild(ulElement);
		tree.slip.setTocElem(containerElement);
		// innerHTML += "</ul>";
	    }
	    console.log("debug tree, will return", containerElement);
	    // containerElement.addEventListener("click", () => { console.log(stackWithNumbers);});
	    return containerElement;
	};
	toc.innerHTML = "";
	// toc.innerHTML = innerHTML;
	toc.appendChild(displayTree(tree, []));
    };
    
    // this.getRootSlip = () => rootSlip;
    this.setRootSlip = (root) => {
	rootSlip = root;
	stack = [rootSlip];
    };
    this.getRootSlip = () => rootSlip;
    this.start = () => {
	stack = [rootSlip];
	this.next();
    };
    this.restart = () => {
	stack = [rootSlip];
	rootSlip.refreshAll();
	this.next();
    };
};
