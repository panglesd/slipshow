class SlipFigure extends HTMLImageElement {
    // Pour spécifier les attributs qui, changés, appellent "attributeChangedCallback"
    static get observedAttributes() {return ['figure-name']; };

    constructor() {
	// Toujours appeler "super" d'abord dans le constructeur
	super();
	if (typeof(this.internalStep) == "undefined") {
 	    this.internalStep = 0;   
	}
	this.img = [];
	this.maxStep = 0;
	this.figureName = this.getAttribute("figure-name");
	this.promise = this.preloadImages(0).then(() => {
	    this.updateSRC();
	});
    }
    preloadImage(i) {
	return new Promise((resolve, reject) => {
	    this.img[i] = new Image();
	    this.img[i].onload = () => resolve();
	    this.img[i].onerror = reject;
	    this.img[i].src = this.getURL(i);
	});
    }
    preloadImages(i) {
	return new Promise((resolve, reject) => {
	    this.preloadImage(i).then(()=> {
		this.preloadImages(i+1).then(() => { resolve(); });
	    }).catch(() => {
		this.maxStep = i-1;
		resolve();
	    });	    
	});
    }
    connectedCallback() {
    }

    getURL(i) {
	return "figures/"+this.figureName+"/"+this.figureName+"_"+i+".svg";
    }
    updateSRC() {
	this.src = this.getURL(this.figureStep);
    }
    
    set figureStep(step) {
	this.promise = this.promise.then(() => {
	    if(step > this.maxStep)
		this.internalStep = this.maxStep;
	    else if (step < 0)
		this.internalStep = 0;
	    else
		this.internalStep=step;
	    this.updateSRC();
	});
    }
    get figureStep() {
	return this.internalStep;
    }
    
    attributeChangedCallback(name, oldValue, newValue) {
	if(name == "figure-name") {
	    this.figureName = newValue;
	    this.promise = this.promise.then(() => {
		this.preloadImages(0).then(() => {
		    this.updateSRC();
		});
	    });
	}
    }
    nextFigure() {
	this.figuresStep++;
    }
}

customElements.define('slip-figure', SlipFigure, { extends: "img" });

let myQueryAll = (root, selector, avoid) => {
    avoid = avoid || "slip-slip";
    if (!root.id)
	root.id = '_' + Math.random().toString(36).substr(2, 15);    let allElem = Array.from(root.querySelectorAll(selector));
    let separatedSelector = selector.split(",").map(selec => "#"+root.id+" " + avoid + " " + selec).join();
    // console.log("debug myQueryAll", selector, "VS",  separatedSelector);
    let other = Array.from(root.querySelectorAll(separatedSelector));
    // let other = Array.from(root.querySelectorAll("#"+root.id+" " + avoid + " " + separatedSelector));
    return allElem.filter(value => !other.includes(value));
};
window.myQueryAll = myQueryAll;

function cloneNoSubslip (elem) {
    let newElem = elem.cloneNode(false);
    elem.childNodes.forEach((child) => {
	if(child.tagName && child.tagName == "SLIP-SLIP"){
	    let placeholder = document.createElement(child.tagName);
	    placeholder.classList.add("toReplace");
	    newElem.appendChild(placeholder);
	}
	else if(child.tagName && child.tagName == "CANVAS" && child.classList.contains("sketchpad")){
	    let placeholder = document.createElement(child.tagName);
	    placeholder.classList.add("toReplaceSketchpad");
	    newElem.appendChild(placeholder);
	}
	else
	    newElem.appendChild(cloneNoSubslip(child));
    });
    if(newElem.tagName == "SLIP-SLIP")
	console.log("debug cloneNosubslip", newElem);
    return newElem;
}
function replaceSubslips(clone, subslips, sketchpad, sketchpadHighlight) {
    let placeholders = myQueryAll(clone, ".toReplace");
    subslips.forEach((subslip, index) => {
	placeholders[index].replaceWith(subslip);
    });
    console.log("debug cloneNosubslip2", myQueryAll(clone, ".toReplaceSketchpad"));
    let sketchPlaceholder = myQueryAll(clone, ".toReplaceSketchpad");
    sketchPlaceholder[0].replaceWith(sketchpad);
    sketchPlaceholder[1].replaceWith(sketchpadHighlight);
}

var IUtil = /*#__PURE__*/Object.freeze({
	__proto__: null,
	myQueryAll: myQueryAll,
	cloneNoSubslip: cloneNoSubslip,
	replaceSubslips: replaceSubslips
});

// import Hammer from 'hammerjs';

function IController (ng) {
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
	clear_annotations_keys = ["X"],
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
	if(clear_annotations_keys.includes(ev.key) && activated) { engine.setTool("clear-all"); }    
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
}

// make a class for Point
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  set(x, y) {
    this.x = x;
    this.y = y;
  }
}

// make a class for the mouse data
class Mouse extends Point {
  constructor() {
    super(0, 0);
    this.down = false;
    this.previous = new Point(0, 0);
  }
}

var mouse = { Mouse, Point };

const C = {};
C.floodFillInterval = 100;
C.maxLineThickness = 50;
C.minLineThickness = 1;
C.lineThicknessRange = C.maxLineThickness - C.minLineThickness;
C.thicknessIncrement = 0.5;
C.minSmoothingFactor = 0.87;
C.initialSmoothingFactor = 0.85;
C.weightSpread = 10;
C.initialThickness = 2;

var constants = C;

class AtramentEventTarget {
  constructor() {
    this.eventListeners = new Map();
  }

  addEventListener(eventName, handler) {
    const handlers = this.eventListeners.get(eventName) || new Set();
    handlers.add(handler);
    this.eventListeners.set(eventName, handlers);
  }

  removeEventListener(eventName, handler) {
    const handlers = this.eventListeners.get(eventName);
    if (!handlers) return;
    handlers.delete(handler);
  }

  dispatchEvent(eventName, data) {
    const handlers = this.eventListeners.get(eventName);
    if (!handlers) return;
    [...handlers].forEach(handler => handler(data));
  }
}

var events = { AtramentEventTarget };

function createCommonjsModule(fn, module) {
	return module = { exports: {} }, fn(module, module.exports), module.exports;
}

var pixels = createCommonjsModule(function (module, exports) {
exports.lineDistance = (x1, y1, x2, y2) => {
  // calculate euclidean distance between (x1, y1) and (x2, y2)
  const xs = Math.pow(x2 - x1, 2);
  const ys = Math.pow(y2 - y1, 2);
  return Math.sqrt(xs + ys);
};

exports.hexToRgb = (hexColor) => {
  // Since input type color provides hex and ImageData accepts RGB need to transform
  const m = hexColor.match(/^#?([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i);
  return [
    parseInt(m[1], 16),
    parseInt(m[2], 16),
    parseInt(m[3], 16)
  ];
};

exports.matchColor = (data, compR, compG, compB, compA) => (pixelPos) => {
  // Pixel color equals comp color?
  const r = data[pixelPos];
  const g = data[pixelPos + 1];
  const b = data[pixelPos + 2];
  const a = data[pixelPos + 3];

  return (r === compR && g === compG && b === compB && a === compA);
};

exports.colorPixel = (data, fillR, fillG, fillB, startColor, alpha) => {
  const matcher = exports.matchColor(data, ...startColor);

  return (pixelPos) => {
    // Update fill color in matrix
    data[pixelPos] = fillR;
    data[pixelPos + 1] = fillG;
    data[pixelPos + 2] = fillB;
    data[pixelPos + 3] = alpha;

    if (!matcher(pixelPos + 4)) {
      data[pixelPos + 4] = data[pixelPos + 4] * 0.01 + fillR * 0.99;
      data[pixelPos + 4 + 1] = data[pixelPos + 4 + 1] * 0.01 + fillG * 0.99;
      data[pixelPos + 4 + 2] = data[pixelPos + 4 + 2] * 0.01 + fillB * 0.99;
      data[pixelPos + 4 + 3] = data[pixelPos + 4 + 3] * 0.01 + alpha * 0.99;
    }

    if (!matcher(pixelPos - 4)) {
      data[pixelPos - 4] = data[pixelPos - 4] * 0.01 + fillR * 0.99;
      data[pixelPos - 4 + 1] = data[pixelPos - 4 + 1] * 0.01 + fillG * 0.99;
      data[pixelPos - 4 + 2] = data[pixelPos - 4 + 2] * 0.01 + fillB * 0.99;
      data[pixelPos - 4 + 3] = data[pixelPos - 4 + 3] * 0.01 + alpha * 0.99;
    }
  };
};
});
var pixels_1 = pixels.lineDistance;
var pixels_2 = pixels.hexToRgb;
var pixels_3 = pixels.matchColor;
var pixels_4 = pixels.colorPixel;

const { Mouse: Mouse$1, Point: Point$1 } = mouse;

const { AtramentEventTarget: AtramentEventTarget$1 } = events;


const DrawingMode = {
  DRAW: 'draw',
  ERASE: 'erase',
  FILL: 'fill',
  DISABLED: 'disabled'
};

const PathDrawingModes = [DrawingMode.DRAW, DrawingMode.ERASE];

var atrament = class Atrament extends AtramentEventTarget$1 {
  constructor(selector, config = {}) {
    if (typeof window === 'undefined') {
      throw new Error('Looks like we\'re not running in a browser');
    }

    super();

    // get canvas element
    if (selector instanceof window.Node && selector.tagName === 'CANVAS') this.canvas = selector;
    else if (typeof selector === 'string') this.canvas = document.querySelector(selector);
    else throw new Error(`can't look for canvas based on '${selector}'`);
    if (!this.canvas) throw new Error('canvas not found');

    // set external canvas params
    this.canvas.width = config.width || this.canvas.width;
    this.canvas.height = config.height || this.canvas.height;

    // create a mouse object
    this.mouse = new Mouse$1();

    // mousemove handler
    const mouseMove = (event) => {
      if (event.cancelable) {
        event.preventDefault();
      }

      const rect = this.canvas.getBoundingClientRect();
      const position = event.changedTouches && event.changedTouches[0] || event;
      let x = position.offsetX;
      let y = position.offsetY;

      if (typeof x === 'undefined') {
        x = position.clientX - rect.left;
      }
      if (typeof y === 'undefined') {
        y = position.clientY - rect.top;
      }

      const { mouse } = this;
      // draw if we should draw
      if (mouse.down && PathDrawingModes.includes(this.mode)) {
        const { x: newX, y: newY } = this.draw(x, y, mouse.previous.x, mouse.previous.y);

        if (!this._dirty && this.mode === DrawingMode.DRAW && (x !== mouse.x || y !== mouse.y)) {
          this._dirty = true;
          this.fireDirty();
        }

        mouse.set(x, y);
        mouse.previous.set(newX, newY);
      }
      else {
        mouse.set(x, y);
      }
    };

    // mousedown handler
    const mouseDown = (event) => {
      if (event.cancelable) {
        event.preventDefault();
      }
      // update position just in case
      mouseMove(event);

      // if we are filling - fill and return
      if (this.mode === DrawingMode.FILL) {
        this.fill();
        return;
      }
      // remember it
      const { mouse } = this;
      mouse.previous.set(mouse.x, mouse.y);
      mouse.down = true;

      this.beginStroke(mouse.previous.x, mouse.previous.y);
    };

    const mouseUp = (e) => {
      if (this.mode === DrawingMode.FILL) {
        return;
      }

      const { mouse } = this;

      if (!mouse.down) {
        return;
      }

      const position = e.changedTouches && e.changedTouches[0] || e;
      const x = position.offsetX;
      const y = position.offsetY;
      mouse.down = false;

      if (mouse.x === x && mouse.y === y && PathDrawingModes.includes(this.mode)) {
        const { x: nx, y: ny } = this.draw(mouse.x, mouse.y, mouse.previous.x, mouse.previous.y);
        mouse.previous.set(nx, ny);
      }

      this.endStroke(mouse.x, mouse.y);
    };

    // attach listeners
    this.canvas.addEventListener('mousemove', mouseMove);
    this.canvas.addEventListener('mousedown', mouseDown);
    document.addEventListener('mouseup', mouseUp);
    this.canvas.addEventListener('touchstart', mouseDown);
    this.canvas.addEventListener('touchend', mouseUp);
    this.canvas.addEventListener('touchmove', mouseMove);

    // helper for destroying Atrament (removing event listeners)
    this.destroy = () => {
      this.clear();
      this.canvas.removeEventListener('mousemove', mouseMove);
      this.canvas.removeEventListener('mousedown', mouseDown);
      document.removeEventListener('mouseup', mouseUp);
      this.canvas.removeEventListener('touchstart', mouseDown);
      this.canvas.removeEventListener('touchend', mouseUp);
      this.canvas.removeEventListener('touchmove', mouseMove);
    };

    // set internal canvas params
    this.context = this.canvas.getContext('2d');
    this.context.globalCompositeOperation = 'source-over';
    this.context.globalAlpha = 1;
    this.context.strokeStyle = config.color || 'rgba(0,0,0,1)';
    this.context.lineCap = 'round';
    this.context.lineJoin = 'round';
    this.context.translate(0.5, 0.5);

    this._filling = false;
    this._fillStack = [];

    // set drawing params
    this.recordStrokes = false;
    this.strokeMemory = [];

    this.smoothing = constants.initialSmoothingFactor;
    this._thickness = constants.initialThickness;
    this._targetThickness = this._thickness;
    this._weight = this._thickness;
    this._maxWeight = this._thickness + constants.weightSpread;

    this._mode = DrawingMode.DRAW;
    this.adaptiveStroke = true;

    // update from config object
    ['weight', 'smoothing', 'adaptiveStroke', 'mode']
      .forEach(key => config[key] === undefined ? 0 : this[key] = config[key]);
  }

  /**
   * Begins a stroke at a given position
   *
   * @param {number} x
   * @param {number} y
   */
  beginStroke(x, y) {
    this.context.beginPath();
    this.context.moveTo(x, y);

    if (this.recordStrokes) {
      this.strokeMemory.push(new Point$1(x, y));
    }
    this.dispatchEvent('strokestart', { x, y });
  }

  /**
   * Ends a stroke at a given position
   *
   * @param {number} x
   * @param {number} y
   */
  endStroke(x, y) {
    this.context.closePath();

    if (this.recordStrokes) {
      this.strokeMemory.push(new Point$1(x, y));
    }
    this.dispatchEvent('strokeend', { x, y });

    if (this.recordStrokes) {
      const stroke = {
        points: this.strokeMemory.slice(),
        mode: this.mode,
        weight: this.weight,
        smoothing: this.smoothing,
        color: this.color,
        adaptiveStroke: this.adaptiveStroke
      };

      this.dispatchEvent('strokerecorded', { stroke });
    }
    this.strokeMemory = [];
  }

  /**
   * Draws a smooth quadratic curve with adaptive stroke thickness
   * between two points
   *
   * @param {number} x current X coordinate
   * @param {number} y current Y coordinate
   * @param {number} prevX previous X coordinate
   * @param {number} prevY previous Y coordinate
   */
  draw(x, y, prevX, prevY) {
    if (this.recordStrokes) {
      this.strokeMemory.push(new Point$1(x, y));
    }

    const { context } = this;
    // calculate distance from previous point
    const rawDist = pixels.lineDistance(x, y, prevX, prevY);

    // now, here we scale the initial smoothing factor by the raw distance
    // this means that when the mouse moves fast, there is more smoothing
    // and when we're drawing small detailed stuff, we have more control
    // also we hard clip at 1
    const smoothingFactor = Math.min(constants.minSmoothingFactor, this.smoothing + (rawDist - 60) / 3000);

    // calculate processed coordinates
    const procX = x - (x - prevX) * smoothingFactor;
    const procY = y - (y - prevY) * smoothingFactor;

    // recalculate distance from previous point, this time relative to the smoothed coords
    const dist = pixels.lineDistance(procX, procY, prevX, prevY);

    if (this.adaptiveStroke) {
      // calculate target thickness based on the new distance
      this._targetThickness = (dist - constants.minLineThickness)
        / constants.lineThicknessRange * (this._maxWeight - this._weight) + this._weight;
      // approach the target gradually
      if (this._thickness > this._targetThickness) {
        this._thickness -= constants.thicknessIncrement;
      }
      else if (this._thickness < this._targetThickness) {
        this._thickness += constants.thicknessIncrement;
      }
      // set line width
      context.lineWidth = this._thickness;
    }
    else {
      // line width is equal to default weight
      context.lineWidth = this._weight;
    }

    // draw using quad interpolation
    context.quadraticCurveTo(prevX, prevY, procX, procY);
    context.stroke();

    return { x: procX, y: procY };
  }

  get color() {
    return this.context.strokeStyle;
  }

  set color(c) {
    if (typeof c !== 'string') throw new Error('wrong argument type');
    this.context.strokeStyle = c;
  }

  get weight() {
    return this._weight;
  }

  set weight(w) {
    if (typeof w !== 'number') throw new Error('wrong argument type');
    this._weight = w;
    this._thickness = w;
    this._targetThickness = w;
    this._maxWeight = w + constants.weightSpread;
  }

  get mode() {
    return this._mode;
  }

  set mode(m) {
    if (typeof m !== 'string') throw new Error('wrong argument type');
    switch (m) {
      case DrawingMode.ERASE:
        this._mode = DrawingMode.ERASE;
        this.context.globalCompositeOperation = 'destination-out';
        break;
      case DrawingMode.FILL:
        this._mode = DrawingMode.FILL;
        this.context.globalCompositeOperation = 'source-over';
        break;
      case DrawingMode.DISABLED:
        this._mode = DrawingMode.DISABLED;
        break;
      default:
        this._mode = DrawingMode.DRAW;
        this.context.globalCompositeOperation = 'source-over';
        break;
    }
  }

  isDirty() {
    return !!this._dirty;
  }

  fireDirty() {
    this.dispatchEvent('dirty');
  }

  clear() {
    if (!this.isDirty) {
      return;
    }

    this._dirty = false;
    this.dispatchEvent('clean');

    // make sure we're in the right compositing mode, and erase everything
    if (this.mode === DrawingMode.ERASE) {
      this.mode = DrawingMode.DRAW;
      this.context.clearRect(-10, -10, this.canvas.width + 20, this.canvas.height + 20);
      this.mode = DrawingMode.ERASE;
    }
    else {
      this.context.clearRect(-10, -10, this.canvas.width + 20, this.canvas.height + 20);
    }
  }

  toImage() {
    return this.canvas.toDataURL();
  }

  fill() {
    const { mouse } = this;
    const { context } = this;
    // converting to Array because Safari 9
    const startColor = Array.from(context.getImageData(mouse.x, mouse.y, 1, 1).data);

    if (!this._filling) {
      const { x, y } = mouse;
      this.dispatchEvent('fillstart', { x, y });
      this._filling = true;
      setTimeout(() => { this._floodFill(mouse.x, mouse.y, startColor); }, constants.floodFillInterval);
    }
    else {
      this._fillStack.push([
        mouse.x,
        mouse.y,
        startColor
      ]);
    }
  }

  _floodFill(_startX, _startY, startColor) {
    const { context } = this;
    const startX = Math.floor(_startX);
    const startY = Math.floor(_startY);
    const canvasWidth = context.canvas.width;
    const canvasHeight = context.canvas.height;
    const pixelStack = [[startX, startY]];
    // hex needs to be trasformed to rgb since colorLayer accepts RGB
    const fillColor = pixels.hexToRgb(this.color);
    // Need to save current context with colors, we will update it
    const colorLayer = context.getImageData(0, 0, context.canvas.width, context.canvas.height);
    const alpha = Math.min(context.globalAlpha * 10 * 255, 255);
    const colorPixel = pixels.colorPixel(colorLayer.data, ...fillColor, startColor, alpha);
    const matchColor = pixels.matchColor(colorLayer.data, ...startColor);
    const matchFillColor = pixels.matchColor(colorLayer.data, ...[...fillColor, 255]);

    // check if we're trying to fill with the same colour, if so, stop
    if (matchFillColor((startY * context.canvas.width + startX) * 4)) {
      this._filling = false;
      this.dispatchEvent('fillend', {});
      return;
    }

    while (pixelStack.length) {
      const newPos = pixelStack.pop();
      const x = newPos[0];
      let y = newPos[1];

      let pixelPos = (y * canvasWidth + x) * 4;

      while (y-- >= 0 && matchColor(pixelPos)) {
        pixelPos -= canvasWidth * 4;
      }
      pixelPos += canvasWidth * 4;

      ++y;

      let reachLeft = false;
      let reachRight = false;

      while (y++ < canvasHeight - 1 && matchColor(pixelPos)) {
        colorPixel(pixelPos);

        if (x > 0) {
          if (matchColor(pixelPos - 4)) {
            if (!reachLeft) {
              pixelStack.push([x - 1, y]);
              reachLeft = true;
            }
          }
          else if (reachLeft) {
            reachLeft = false;
          }
        }

        if (x < canvasWidth - 1) {
          if (matchColor(pixelPos + 4)) {
            if (!reachRight) {
              pixelStack.push([x + 1, y]);
              reachRight = true;
            }
          }
          else if (reachRight) {
            reachRight = false;
          }
        }

        pixelPos += canvasWidth * 4;
      }
    }

    // Update context with filled bucket!
    context.putImageData(colorLayer, 0, 0);

    if (this._fillStack.length) {
      this._floodFill(...this._fillStack.shift());
    }
    else {
      this._filling = false;
      this.dispatchEvent('fillend', {});
    }
  }
};

var atrament$1 = atrament;

function Slip(name, fullName, actionL, ng, options) {

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
	}    };
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
	let savedClass = this.element.className;
	let r = this.doRefresh();
	this.element.className = savedClass;
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
	replaceSubslips(clone, subSlipList, this.sketchpadCanvas, this.sketchpadCanvasHighlight);
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
	this.getEngine;
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
	    this.sketchpad.weight = 1;
	} else if(tool == "drawing-erase") {
	    this.element.classList.add("drawing");
	    this.sketchpad.weight = 20;
	    this.sketchpad.mode = "erase";
	} else if(tool == "clear-all") {
	    this.sketchpad.clear();
	    this.sketchpadHighlight.clear();
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
    // scale, rotate, delay
    this.scale = parseFloat(this.element.getAttribute("scale"));
    if(typeof this.scale == "undefined" || isNaN(this.scale)) this.scale = 1;
    this.rotate = parseFloat(this.element.getAttribute("rotate")) || 0;
    this.delay = isNaN(parseFloat(this.element.getAttribute("delay"))) ? 0 : (parseFloat(this.element.getAttribute("delay")));
    // canvas for drawing
    var that = this;
    console.log("element bug before", this.element, that.element);
    let element = this.element;
    setTimeout(function() {
	let canvas = document.createElement('canvas');
	canvas.height = element.offsetHeight/that.scale;
	canvas.width = element.offsetWidth/that.scale;
	console.log("element bug after", element, that.element);
	canvas.classList.add("sketchpad", "drawing");
	canvas.style.opacity = "1";
	that.sketchpadCanvas = canvas;
	element.firstChild.firstChild.appendChild(canvas);
	that.sketchpad = new atrament$1(canvas);
	that.sketchpad.smoothing = 0.2;
	that.sketchpad.color = "blue";
    // }, 0);
    // canvas for highlighting 
    // setTimeout(function() {
	let canvas2 = document.createElement('canvas');
	canvas2.height = that.element.offsetHeight/that.scale;
	canvas2.width = that.element.offsetWidth/that.scale;
	canvas2.classList.add("sketchpad", "sketchpad-highlighting");
	canvas2.style.opacity = "0.5";
	that.sketchpadCanvasHighlight = canvas2;
	element.firstChild.firstChild.appendChild(canvas2);
	that.sketchpadHighlight = new atrament$1(canvas2);
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

function IEngine (root) {
    function prepareRoot (rootElem) {
	let container = document.createElement("div");
	container.innerHTML = 
	    '	\
	<div class="toc-slip" style="display:none;"></div>\
        <div id="open-window">\
	  <div class="cpt-slip">0</div>\
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
	</div>';
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
	document.querySelectorAll(".background-canvas").forEach((elem)=> {elem.addEventListener("click", (ev) => { console.log("vous avez cliquez aux coordonnées : ", ev.layerX, ev.layerY); });});	
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
	    let subslips = myQueryAll(elem, "slip-slip");
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
    this.enter = (n) => {
	this.gotoSlip(n);
	this.push(n);
	this.next();
    };
    this.next = () => {
	if(document.querySelector(".toc-slip").innerHTML == "")
	    this.showToC();
	// return true if and only if the stack changed
	let currentSlide = this.getCurrentSlip();
	let n = currentSlide.next();
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
	if(slip.element.tagName == "SLIP-SLIP")
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

    // ******************************
    // Function for writing and highlighting
    // ******************************

    this.setTool = (tool) => {
	this.getCurrentSlip().setTool(tool);
    };

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
	this.next();
	return this;
    };
    this.restart = () => {
	stack = [rootSlip];
	rootSlip.refreshAll();
	this.next();
    };
    let controller = new IController(this);
    this.getController = () => controller;
}

// import "./css/slip.css";
// import "./css/theorem.css";

/**
 * Allows slip-js to be used as a module
 */
const Engine = IEngine;
const Controller = IController;
const Slip$1 = Slip;
const Util = IUtil;

let startSlipshow = () => {
    let engine;
    if(typeof MathJax != "undefined")
	MathJax.startup.promise.then(() => {
	    engine = new Engine(document.querySelector("slip-slipshow")).start();
	});
    else
	engine = new Engine(document.querySelector("slip-slipshow")).start();
    return engine;
};

/**
 * Allows slip-js to be used as simple CDN-included file
 */
// window.Engine = IEngine;
// window.Controller = IController;
// window.Slip = ISlip;
// window.Util = IUtil;

export { Controller, Engine, Slip$1 as Slip, Util, startSlipshow };
//# sourceMappingURL=slipshow.js.map
