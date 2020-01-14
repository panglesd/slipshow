import { cloneNoSubslip, myQueryAll, replaceSubslips } from './util'

export default function (name, fullName, actionL, ng, options) {
    let engine = ng;
    this.fullName = fullName;
    this.name = name;
    
    this.getEngine = () => engine;
    this.setEngine = (ng) => engine = ng;
    
    // let presentation = present;
    // this.getPresentation = () => presentation;
    // this.setPresentation = (present) => presentation = present;
    
    this.element = document.querySelector("#"+name);
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
    this.getActionList = () => {
	let ret = [];
	for(let i = 0;i <= this.getMaxNext(); i++) {
	    if(typeof actionList[i] == "function" || actionList[i] instanceof Slip)
		ret[i] = actionList[i];
	    else
		ret[i] = () => {};
	}
	return ret;
    };
    this.setNthAction = (n,action) => {actionList[n] = action;};

    this.getSubSlipList = function () {
	return actionList.filter((action) => action instanceof Slip);
    };
    
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

    this.setTocElem = (tocElem) => {this.tocElem = tocElem;};
    this.updateToC = () => {
	if(!this.tocElem)
	    return;
	let list = myQueryAll(this.tocElem, "li", "li");
	console.log("debug updateToc", this.name, list);
	let i;
	for(i=0;i<this.getActionIndex(); i++) {
	    console.log("debug updateToc, before with i=", i);
	    list[i].classList.remove("before", "after", "current");
	    list[i].classList.add("before");	    
	}
	// if(i!=0) i++;
	if(i<=this.getActionIndex()) {
	    console.log("debug updateToc, current with i=", i);
	    list[i].classList.remove("before", "after", "current");
	    list[i].classList.add("current");
	    i++;
	}
	for(i;i<=this.getMaxNext(); i++) {
	    console.log("debug updateToc, after with i=", i);
	    list[i].classList.remove("before", "after", "current");
	    list[i].classList.add("after");
	}	
    };
    this.incrIndex = () => {
	console.log("incrIndex");
	actionIndex = actionIndex+1;
	this.doAttributes();
	this.updateToC();
	// if(this.tocElem)
	//     this.tocElem.innerText = actionIndex;
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
	this.updateToC();
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
    this.refreshAll = () => {
	actionList.filter((elem) => elem instanceof Slip).forEach((subslip) => { subslip.refreshAll();});
	this.doRefresh();
    };
    this.doRefresh = () => {
	this.setActionIndex(-1);
	let subSlipList = myQueryAll(this.element, ".slip");;
	let clone = clonedElement.cloneNode(true);
	replaceSubslips(clone, subSlipList);
	this.element.replaceWith(clone);
	this.element = clone;
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
	delete(this.currentX);
	delete(this.currentY);
	engine.gotoSlip(this);
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
