import { cloneNoSubslip, myQueryAll, replaceSubslips } from './util'
import Atrament from 'atrament';
export default function Slip(name, fullName, actionL, ng, options) {

    // ******************************
    // Action List
    // ******************************

    this.generateActionList = function() {
	console.log("debug generateactionlist", this.name);
	let newActionList = [];
	this.queryAll("slip-slip[enter-at]").forEach((slip) => {
	    console.log("new slip with ", slip, null, null, ng, {});
	    newActionList[slip.getAttribute("enter-at")] = new Slip(slip, "", [], ng, {});
	});
	return newActionList;
    };
    this.addSubSlips = function() {
	console.log("debug generateactionlist", this.name);
	let newActionList = [];
	this.queryAll("slip-slip[enter-at]").forEach((slip) => {
	    console.log("new slip with ", slip, null, null, ng, {});
	    this.setNthAction(slip.getAttribute("enter-at"), new Slip(slip, "", [], ng, {}));
	});
	return newActionList;
    };
    let actionList = actionL;// || this.generateActionList();
    this.setAction = (actionL) => {actionList = actionL;};
    this.getActionList = () => {
	let ret = [];
	for(let i = 0;i <= this.getMaxNext(); i++) {
	    if(this.pauseSlipList[i] instanceof Slip)
		ret[i] = this.pauseSlipList[i];
	    else if(typeof actionList[i] == "function" || actionList[i] instanceof Slip)
		ret[i] = actionList[i];
	    else
		ret[i] = () => {};
	}
	return ret;
    };
    this.setNthAction = (n,action) => {actionList[n] = action;};
    this.getCurrentSubSlip = () => {
	if(actionList[this.getActionIndex()] instanceof Slip)
	    return actionList[this.getActionIndex()];
	if(this.pauseSlipList[this.getActionIndex()] instanceof Slip)
	    return this.pauseSlipList[this.getActionIndex()];
	return false;
    };
    this.nextStageNeedGoto = () => {
	if(actionList[this.getActionIndex()+1] instanceof Slip)
	    return false;
	if(this.pauseSlipList[this.getActionIndex()+1] instanceof Slip)
	    return false;
	if(this.getActionIndex() >= this.getMaxNext())
	    return false;
	return true;
    };
    this.getSubSlipList = function () {
	return this.getActionList().filter((action) => action instanceof Slip);
    };

    // ******************************
    // Action Index
    // ******************************
    let actionIndex = -1;
    this.setActionIndex = (actionI) => actionIndex = actionI;
    this.getActionIndex = () => actionIndex;
    this.getMaxNext = () => {
	if(this.maxNext)
	    return this.maxNext;
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
	 "exec-at",
	 "enter-at",
	 "focus-at",
	 "unfocus-at",
	 "figure-next-at",
	 "figure-previous-at",
	].forEach((attr) => {
	    this.queryAll("*["+attr+"]").forEach((elem) => {
		elem.getAttribute(attr).split(" ").forEach((strMax) => {
		    maxTemp = Math.max(Math.abs(parseInt(strMax)),maxTemp);
		});
	    });
	});
	let sumArray = this.queryAll("[pause], [step], [auto-enter], [immediate-enter]").map((elem) => {
	    if(elem.hasAttribute("pause") && elem.getAttribute("pause") != "")
		return parseInt(elem.getAttribute("pause"));
	    if(elem.hasAttribute("step") && elem.getAttribute("step") != "")
		return parseInt(elem.getAttribute("step"));
	    return 1; });
	maxTemp = Math.max(maxTemp, sumArray.reduce((a,b) => a+b, 0));
	this.maxNext = maxTemp;
	return maxTemp;	
    };
    
    // ******************************
    // Queries
    // ******************************
    this.queryAll = (quer) => {
	return myQueryAll(this.element, quer);
	// let allElem = Array.from(this.element.querySelectorAll(quer));
	// let other = Array.from(this.element.querySelectorAll("#"+this.name+" slip "+quer));
	// return allElem.filter(value => !other.includes(value));
    };
    this.query = (quer) => {
	if(typeof quer != "string") return quer;
	return this.queryAll(quer)[0];
    };
    this.findSubslipByID = (id) => {
	let goodSubslip = this.getSubSlipList().find((subslip) => {
	    if(subslip.name == id)
		return 1;
	    return subslip.findSubslipByID(id);
	});
	if(!goodSubslip)
	    return false;
	if (goodSubslip.name == id) 
	    return goodSubslip;
	return goodSubslip.findSubslipByID(id);
    };
    
    // ******************************
    // Coordinates
    // ******************************
    this.findSlipCoordinate = () => { // rename to getCoordInUniverse
	let coord = engine.getCoordinateInUniverse(this.element);
	console.log("debug findslipcoordinate", coord);
	coord.scale *= this.scale;
	coord.y = coord.y + 0.5*coord.scale;
	coord.x = coord.centerX;
	console.log("debug findslipcoordinate", coord);
	return coord;
    };


    // ******************************
    // Pause functions
    // ******************************
    this.updatePauseAncestors = () => {
	this.queryAll(".pauseAncestor").forEach((elem) => {elem.classList.remove("pauseAncestor");});
	let pause = this.query("[pause]");
	while(pause && pause.tagName != "SLIP-SLIP") {
	    pause.classList.add("pauseAncestor");
	    pause = pause.parentElement;
	};
    };
    this.unpause = (pause) => {
	if(pause.hasAttribute("static-at-unpause")) {
	    if(pause.getAttribute("static-at-unpause") == "")
		this.makeStatic(pause);
	    else
		pause.getAttribute("static-at-unpause").split(" ").map((strID) => {
		    this.makeStatic("#"+strID);
		});
	}
	if(pause.hasAttribute("unstatic-at-unpause")) {
	    if(pause.getAttribute("unstatic-at-unpause") == "")
		this.makeUnStatic(pause);
	    else
		pause.getAttribute("unstatic-at-unpause").split(" ").map((strID) => {
		    this.makeUnStatic("#"+strID);
		});
	}
	if(pause.hasAttribute("down-at-unpause")) {
	    if(pause.getAttribute("down-at-unpause") == "")
		this.moveDownTo(pause, 1);
	    else
		this.moveDownTo("#"+pause.getAttribute("down-at-unpause"), 1);			
	}
	if(pause.hasAttribute("up-at-unpause")) {
	    if(pause.getAttribute("up-at-unpause") == "")
		this.moveUpTo(pause, 1);
	    else
		this.moveUpTo("#"+pause.getAttribute("up-at-unpause"), 1);
	}
	if(pause.hasAttribute("center-at-unpause")) {
	    if(pause.getAttribute("center-at-unpause") == "")
		this.moveCenterTo(pause, 1);
	    else
		this.moveCenterTo("#"+pause.getAttribute("center-at-unpause"), 1);
	}
	if(pause.hasAttribute("exec-at-unpause")) {
	    if(pause.getAttribute("exec-at-unpause") == "")
		this.executeScript(pause);
	    else
		pause.getAttribute("exec-at-unpause").split(" ").map((strID) => {
		    this.executeScript("#"+strID);	
		});
	}
	if(pause.hasAttribute("reveal-at-unpause")) {
	    if(pause.getAttribute("reveal-at-unpause") == "")
		this.reveal(pause);
	    else
		pause.getAttribute("reveal-at-unpause").split(" ").map((strID) => {
		    this.reveal("#"+strID);
		});
	}
	if(pause.hasAttribute("hide-at-unpause")) {
	    if(pause.getAttribute("hide-at-unpause") == "")
		this.hide(pause);
	    else
		pause.getAttribute("hide-at-unpause").split(" ").map((strID) => {
		    this.hide("#"+strID);
		});
	}
	if(pause.hasAttribute("figure-set-at-unpause")) {
	    let [figureID, figureStep] = pause.getAttribute("figure-set-at-unpause").split(" ");
	    this.query("#"+figureID).figureStep = figureStep;
	}
	if(pause.hasAttribute("figure-next-at-unpause")) {
	    pause.getAttribute("figure-next-at-unpause").split(" ").map((figureID) => {
		this.query("#"+figureID).figureStep++;
	    });
	}
	if(pause.hasAttribute("figure-previous-at-unpause")) {
	    pause.getAttribute("figure-previous-at-unpause").split(" ").map((figureID) => {
		this.query("#"+figureID).figureStep--;
	    });
	}
	if(pause.hasAttribute("focus-at-unpause")) {
	    if(pause.getAttribute("focus-at-unpause") == "")
		this.focus(pause);
	    else
		this.focus("#"+pause.getAttribute("focus-at-unpause"));
	}
	if(pause.hasAttribute("unfocus-at-unpause")){
	    if(pause.getAttribute("unfocus-at-unpause") == "")
		this.unfocus(pause);
	    else
		this.unfocus("#"+pause.getAttribute("unfocus-at-unpause"));
	}
    };
    this.incrPause = () => {
	let pause = this.query("[pause], [auto-enter]:not([auto-enter=\"0\"]), [immediate-enter]:not([immediate-enter=\"0\"]), [step]");
	// let pause = this.query("[pause]");
	if(pause) {
	    console.log("pause is", this.name, pause);
	    if(pause.hasAttribute("step")) {
		if(!pause.getAttribute("step")) 
		    pause.setAttribute("step", 1);
		let d = pause.getAttribute("step");
		if (d <= 1){
		    pause.removeAttribute("step");
		    this.unpause(pause);
		} else
		    pause.setAttribute("step", d-1);
	    }
	    if(pause.hasAttribute("auto-enter")) {
		pause.setAttribute("auto-enter", 0);
		this.unpause(pause);
	    }
	    if(pause.hasAttribute("immediate-enter")) {
		pause.setAttribute("immediate-enter", 0);
		this.unpause(pause);
	    }
	    if(pause.hasAttribute("pause")) {
		if(!pause.getAttribute("pause")) 
		    pause.setAttribute("pause", 1);
		let d = pause.getAttribute("pause");
		if (d <= 1){
		    pause.removeAttribute("pause");
		    this.unpause(pause);
		} else
		    pause.setAttribute("pause", d-1);
		this.updatePauseAncestors();
	    }
	}
    };

    // ******************************
    // Next functions
    // ******************************
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
	    if(actionIndex < 0) return;
	    if(staticAt.includes(-actionIndex)){
		console.log("make unstatic actionIndex elem", actionIndex, elem);
		this.makeUnStatic(elem);
		// elem.style.position = "absolute";
		// elem.style.visibility = "hidden";
	    }
	    else if(staticAt.includes(actionIndex)) {
		this.makeStatic(elem);
		// elem.style.position = "static";
		// elem.style.visibility = "visible";
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
	this.queryAll("*[focus-at]").forEach((elem) => {
	    let focus = elem.getAttribute("focus-at").split(" ").map((str) => parseInt(str));
	    if(focus.includes(actionIndex))
		this.focus(elem, 1);});	
	this.queryAll("*[unfocus-at]").forEach((elem) => {
	    let focus = elem.getAttribute("unfocus-at").split(" ").map((str) => parseInt(str));
	    if(focus.includes(actionIndex))
		this.unfocus(elem, 1);});	
	this.queryAll("*[exec-at]").forEach((elem) => {
	    let toExec = elem.getAttribute("exec-at").split(" ").map((str) => parseInt(str));
	    if(toExec.includes(actionIndex))
		this.executeScript(elem);});	
	this.queryAll("*[figure-next-at]").forEach((elem) => {
	    let toFigureNext = elem.getAttribute("figure-next-at").split(" ").map((str) => parseInt(str));
	    if(toFigureNext.includes(actionIndex))
		elem.figureStep++;});	
	this.queryAll("*[figure-previous-at]").forEach((elem) => {
	    let toFigureNext = elem.getAttribute("figure-previous-at").split(" ").map((str) => parseInt(str));
	    if(toFigureNext.includes(actionIndex))
		elem.figureStep--;});	
    };
    this.incrIndex = () => {
	console.log("incrIndex", this.name);
	actionIndex = actionIndex+1;
	this.doAttributes();
	if(actionIndex>0)
	    this.incrPause();
	this.updateToC();
    };
    this.next = function () {
	if(actionIndex >= this.getMaxNext())
	    return false;
	this.incrIndex();
	if(typeof actionList[actionIndex] == "function") {
	    actionList[actionIndex](this);
	}
	if(actionList[actionIndex] instanceof Slip){
	    return actionList[actionIndex];
	}
	if(this.pauseSlipList[actionIndex] instanceof Slip)
	    return this.pauseSlipList[actionIndex];
	// let nextSlip = this.query("[pause], [auto-enter]");
	// if(nextSlip.hasAttribute("auto-enter"))
	//     return 
	return true;
    };
    this.previous = () => {
	let savedActionIndex = this.getActionIndex();
	let savedDelay = this.currentDelay;
	this.getEngine().setDoNotMove(true);
	let r = this.doRefresh();
	console.log("gotoslip: we call doRefresh",r);
	if(savedActionIndex == -1)
	    return false;
 	let toReturn;
	while(this.getActionIndex()<savedActionIndex-1){
	    console.log("previous is ca we do next", this.getEngine().getDoNotMove());
	    console.log("(figure) actionIndex is", actionIndex);
	    toReturn = this.next();
	}
	// if(!this.nextStageNeedGoto())
	//     this.getEngine().setDoNotMove(false);
	// while(this.getActionIndex()<savedActionIndex-1)
	//     toReturn = this.next();
	setTimeout(() => {this.getEngine().setDoNotMove(false);},0);
	this.getEngine().gotoSlip(this, {delay:savedDelay});
	return toReturn;

	// return this.next;
    };

    // ******************************
    // ToC functions
    // ******************************
    this.setTocElem = (tocElem) => {this.tocElem = tocElem;};
    this.updateToC = () => {
	if(!this.tocElem)
	    return;
	if(!this.ToCList)
	    this.ToCList = myQueryAll(this.tocElem, "li", "li");
	let i;
	for(i=0;i<this.getActionIndex(); i++) {
	    this.ToCList[i].classList.remove("before", "after", "current");
	    this.ToCList[i].classList.add("before");	    
	}
	if(i<=this.getActionIndex()) {
	    this.ToCList[i].classList.remove("before", "after", "current");
	    this.ToCList[i].classList.add("current");
	    i++;
	}
	for(i;i<=this.getMaxNext(); i++) {
	    this.ToCList[i].classList.remove("before", "after", "current");
	    this.ToCList[i].classList.add("after");
	}	
    };
    this.firstVisit = () => {
	this.updateToC();
	if(options.firstVisit)
	    options.firstVisit(this);
    };
    this.init = () => {
	this.queryAll("*[chg-visib-at]").forEach((elem) => {
	    elem.style.opacity = "0";
	});	
	// this.queryAll("*[static-at]").forEach((elem) => {
	//     elem.style.position = "absolute";
	//     elem.style.visibility = "hidden";
	// });	
//	this.doAttributes();
	this.updatePauseAncestors();
	if(options.init)
	    options.init(this);
    };

    // ******************************
    // Refreshes
    // ******************************
    this.refresh = () => {
	if(actionList[actionIndex] instanceof Slip)
	    actionList[actionIndex].refresh();
	else
	    this.doRefresh();
    };
    this.refreshAll = () => {
	actionList.filter((elem) => elem instanceof Slip).forEach((subslip) => { subslip.refreshAll();});
	this.pauseSlipList.filter((elem) => elem instanceof Slip).forEach((subslip) => { subslip.refreshAll();});
	this.doRefresh();
    };
    this.doRefresh = () => {
	console.log("to Atrament debug",this.element);
	console.log("gotoslip: doRefresh has been called");
	this.setActionIndex(-1);
	let subSlipList = myQueryAll(this.element, "slip-slip");
	console.log("mmdebug", clonedElement);
	console.log("to Atrament debug clonedElement",clonedElement);
	let clone = clonedElement.cloneNode(true);
	replaceSubslips(clone, subSlipList, this.sketchpadCanvas);
	this.element.replaceWith(clone);
	this.element = clone;
	this.init();
	this.firstVisit();
	delete(this.currentX);
	delete(this.currentY);
	delete(this.currentDelay);
	console.log("previous is ca GOTOSLIP FROM 3", options, this.getEngine().getDoNotMove());
	this.getEngine().gotoSlip(this);
    };

    // ******************************
    // Movement, execution and hide/show
    // ******************************
    this.makeUnStatic = (selector, delay, opacity) => {
	let elem = this.query(selector);
	// setTimeout(() => {
	//     elem.style.overflow = "hidden"; 
	//     setTimeout(() => {
	// 	elem.style.transition = "height "+ (typeof(delay) == "undefined" ? "1s" : (delay+"s"));
	// 	if(opacity)
	// 	    elem.style.transition += ", opacity "+ (typeof(delay) == "undefined" ? "1s" : (delay+"s"));
	// 	elem.style.height = (elem.offsetHeight+"px");
	// 	if(opacity)
	// 	    elem.style.opacity = "1";
	// 	setTimeout(() => {
	// 	    if(opacity)
	// 	    	elem.style.opacity = "0"; 
	// 	    elem.style.height = ("0px");}, 10);
	//     }, 0);
	// },0);
	elem.style.position = "absolute";
	elem.style.visibility = "hidden";
    };
    this.makeStatic = (selector) => {
	let elem = this.query(selector);
	elem.style.position = "static";
	elem.style.visibility = "visible";
    };
    this.unfocus = (selector) => {
	this.getEngine().gotoSlip(this, { delay: 1});
    };
    this.focus = (selector) => {
	let elem = this.query(selector);
	this.getEngine().moveToElement(elem, {});
    };

    this.executeScript = (selector) => {
	let elem;
	if(typeof selector == "string") elem = this.query(selector);
	else elem = selector;
	(new Function("slip",elem.innerHTML))(this);
    };
    this.moveUpTo = (selector, delay,  offset) => {
	setTimeout(() => {
	    let elem;
	    if(typeof selector == "string") elem = this.query(selector);
	    else elem = selector;
	    if (typeof offset == "undefined") offset = 0.0125;
	    let coord = this.findSlipCoordinate();
	    let d = ((elem.offsetTop)/1080-offset)*coord.scale;
	    this.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	    // this.currentX = coord.x;
	    // this.currentY = coord.y+d;
	    // this.currentDelay = delay;
	    // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
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
	    this.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	    // this.currentX = coord.x;
	    // this.currentY = coord.y+d;
	    // this.currentDelay = delay;
	    // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
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
	    this.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	    // this.currentX = coord.x;
	    // this.currentY = coord.y+d;
	    // this.currentDelay = delay;
	    // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
	},0);
    };
    this.restoreWindow = () => {
	this.getEngine
    };
    this.moveWindow = (x,y,scale,rotate, delay) => {
	this.currentX = x;
	this.currentY = y;
	this.currentDelay = delay;
	console.log("previous is ca we try to move win", this.getEngine().getDoNotMove());
	console.log("previous is ca ORIGIN 3", x, y, this.getEngine().getDoNotMove());
//	setTimeout(() => {
	    this.getEngine().moveWindow(x, y, scale, rotate, delay);
//	}, 0);
    };
    this.reveal = (selector) => {
	let elem;
	if(typeof selector == "string") elem = this.query(selector);
	else elem = selector;
	elem.style.opacity = "1";
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

    // ******************************
    // Function for writing and highlighting
    // ******************************

    this.setTool = (tool) => {
	this.element.classList.remove("drawing", "highlighting");
	if(tool == "highlighting") {
	    this.element.classList.add("highlighting");
	    this.sketchpadHighlight.mode = "draw";
	} else if(tool == "highlighting-erase") {
	    this.element.classList.add("highlighting");
	    this.sketchpadHighlight.mode = "erase";
	} else if(tool == "drawing") {
	    this.element.classList.add("drawing");
	    this.sketchpad.mode = "draw";
	    this.sketchpad.weight = 2;
	} else if(tool == "drawing-erase") {
	    this.element.classList.add("drawing");
	    this.sketchpad.weight = 20;
	    this.sketchpad.mode = "erase";
	}
    };

    // ******************************
    // Initialisation of the object
    // ******************************
    // engine
    let engine = ng;
    this.getEngine = () => engine;
    this.setEngine = (ng) => engine = ng;
    // element
    this.element =
	typeof name == "string" ?
	document.querySelector(name[0]=="#" ? name : ("#"+name)):
	name;
    // canvas for drawing
    var that = this;
    console.log("element bug before", this.element, that.element);
    let element = this.element;
    setTimeout(function() {
	let canvas = document.createElement('canvas');
	canvas.height = element.offsetHeight;
	canvas.width = element.offsetWidth;
	console.log("element bug after", element, that.element);
	canvas.classList.add("sketchpad", "drawing");
	canvas.style.opacity = "1";
	that.sketchpadCanvas = canvas;
	element.firstChild.firstChild.appendChild(canvas);
	that.sketchpad = new Atrament(canvas);
	that.sketchpad.smoothing = 0.2;
    // }, 0);
    // canvas for highlighting 
    // setTimeout(function() {
	let canvas2 = document.createElement('canvas');
	canvas2.height = that.element.offsetHeight;
	canvas2.width = that.element.offsetWidth;
	canvas2.classList.add("sketchpad", "sketchpad-highlighting");
	canvas2.style.opacity = "0.5";
	that.sketchpadCanvasHighlight = canvas2;
	element.firstChild.firstChild.appendChild(canvas2);
	that.sketchpadHighlight = new Atrament(canvas2);
	that.sketchpadHighlight.color = "yellow";
	that.sketchpadHighlight.weight = 30;
	that.sketchpadHighlight.smoothing = 0.2;
    }, 0);
    // names
    this.name =
	typeof name == "string" ?
	name:
	name.id;
    if(typeof(fullName) == "string")
	this.fullName = fullName ;
    else if (this.element.hasAttribute("toc-title"))
	this.fullName = this.element.getAttribute("toc-title");
    else
	this.fullName = this.name;
    console.log("this name is ", this.name);
    // clonedElement
    let clonedElement;
    if(typeof MathJax != "undefined")
	MathJax.startup.promise.then(() => {
	    setTimeout(() => {clonedElement = cloneNoSubslip(this.element);},0);
	});
    else
	setTimeout(() => {clonedElement = cloneNoSubslip(this.element);},0);
    console.log("to Atrament debug before",this.element);

    this.getCloned = () => clonedElement;
    this.setCloned = (c) => clonedElement = c;
    // scale, rotate, delay
    this.scale = parseFloat(this.element.getAttribute("scale"));
    if(typeof this.scale == "undefined" || isNaN(this.scale)) this.scale = 1;
    this.rotate = parseFloat(this.element.getAttribute("rotate")) || 0;
    this.delay = isNaN(parseFloat(this.element.getAttribute("delay"))) ? 0 : (parseFloat(this.element.getAttribute("delay")));
    // coord
    let coord = this.findSlipCoordinate();
    console.log(coord);
    this.x = coord.x;
    this.y = coord.y;
    // Preparing the slip
    this.init(this, engine);
    // Adding "enter-at" subslips
    this.addSubSlips();
    // Adding "paused-flow" subslips
    this.generatePauseFlowSlipList = function () {
	let slipList = [];
	let bla = this.queryAll("[pause], [step], [auto-enter], [immediate-enter]");
	let step = 1;
	bla.forEach((elem) => {
	    console.log("debug generatePauseFlowsliplist", elem, step);
	    if(elem.hasAttribute("auto-enter")){
		slipList[step] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
		step++;
	    }
	    if(elem.hasAttribute("immediate-enter")){
		// the slip is entered before the pause
		slipList[step-1] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
		step++;
	    }
	    if(elem.hasAttribute("step")){
		console.log("has enter-at-unpause?");
		if(elem.hasAttribute("enter-at-unpause")) {
		    console.log("has enter-at-unpause");
		    if(elem.getAttribute("enter-at-unpause") != "") {
			let s = this.query("#"+elem.getAttribute("enter-at-unpause"));
			slipList[step] = new Slip(s, s.getAttribute("toc-title") || "", [], ng, {});
//			slipList[step + (parseInt(elem.getAttribute("step")) || 1) - 1] = new Slip(s, s.getAttribute("toc-title") || "", [], ng, {});
		    }
		    else
			slipList[step + (parseInt(elem.getAttribute("step")) || 1) - 1] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
		}
		console.log("debug generatePauseFlowsliplist1", elem, step);
		step += parseInt(elem.getAttribute("step")) || 1 ;
		console.log("debug generatePauseFlowsliplist2", elem, step);
	    }
	    if(elem.hasAttribute("pause")){
		if(elem.hasAttribute("enter-at-unpause")) {
		    if(elem.getAttribute("enter-at-unpause") != "") {
			let s = this.query(elem.getAttribute("enter-at-unpause"));
			slipList[step + (parseInt(elem.getAttribute("step")) || 1) - 1] = new Slip(s, s.getAttribute("toc-title") || "", [], ng, {});
		    }
		    else
			slipList[step + (parseInt(elem.getAttribute("step")) || 1) - 1] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
		}
		console.log("debug generatePauseFlowsliplist1", elem, step);
		step += parseInt(elem.getAttribute("pause")) || 1 ;
		console.log("debug generatePauseFlowsliplist1", elem, step);
	    }
	});
	return slipList;
    };
    this.pauseSlipList = this.generatePauseFlowSlipList();
    // this.pauseSlipList = this.queryAll("[pause], [step], [auto-enter]").map((elem) => {
    // 	if(elem.hasAttribute("auto-enter"))
    // 	    return new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
    // 	return null;
    // });
}
