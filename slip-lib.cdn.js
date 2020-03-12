var SlipLib = (function (exports) {
    'use strict';

    let myQueryAll = (root, selector, avoid) => {
      avoid = avoid || ".slip";
      if (!root.id) root.id = '_' + Math.random().toString(36).substr(2, 15);
      let allElem = Array.from(root.querySelectorAll(selector));
      let separatedSelector = selector.split(",").map(selec => "#" + root.id + " " + avoid + " " + selec).join(); // console.log("debug myQueryAll", selector, "VS",  separatedSelector);

      let other = Array.from(root.querySelectorAll(separatedSelector)); // let other = Array.from(root.querySelectorAll("#"+root.id+" " + avoid + " " + separatedSelector));

      return allElem.filter(value => !other.includes(value));
    };
    window.myQueryAll = myQueryAll;
    function cloneNoSubslip(elem) {
      let newElem = elem.cloneNode(false);
      elem.childNodes.forEach(child => {
        if (child.classList && child.classList.contains("slip")) {
          let placeholder = document.createElement(child.tagName);
          placeholder.classList.add("toReplace");
          newElem.appendChild(placeholder);
        } else newElem.appendChild(cloneNoSubslip(child));
      });
      return newElem;
    }
    function replaceSubslips(clone, subslips) {
      let placeholders = myQueryAll(clone, ".toReplace");
      subslips.forEach((subslip, index) => {
        placeholders[index].replaceWith(subslip);
      });
    }

    var IUtil = /*#__PURE__*/Object.freeze({
        __proto__: null,
        myQueryAll: myQueryAll,
        cloneNoSubslip: cloneNoSubslip,
        replaceSubslips: replaceSubslips
    });

    function IEngine (root) {
      function prepareRoot(rootElem) {
        let container = document.createElement("div");
        container.innerHTML = '	<div id="open-window">\
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
        rootElem.querySelectorAll(".slip").forEach(slipElem => {
          setTimeout(() => {
            var scaleContainer = document.createElement('div');
            var slipContainer = document.createElement('div');
            scaleContainer.classList.add("slip-scale-container");
            slipContainer.classList.add("slip-container");
            let fChild;

            while (fChild = slipElem.firstChild) {
              slipContainer.appendChild(fChild);
            }

            scaleContainer.appendChild(slipContainer);
            slipElem.appendChild(scaleContainer);
          }, 0);
        });
        rootElem.style.width = "unset";
        rootElem.style.height = "unset";
        document.querySelectorAll(".background-canvas").forEach(elem => {
          elem.addEventListener("click", ev => {
            console.log("vous avez cliquez aux coordonnées : ", ev.layerX, ev.layerY);
          });
        });
      }

      prepareRoot(root); // Constants

      document.body.style.cursor = "auto";
      let timeOutIds = [];
      document.body.addEventListener("mousemove", ev => {
        timeOutIds.forEach(id => {
          clearTimeout(id);
        });
        document.body.style.cursor = "auto";
        timeOutIds.push(setTimeout(() => {
          document.body.style.cursor = "none";
        }, 5000));
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

      this.getCoord = () => {
        return {
          x: winX,
          y: winY,
          scale: currentScale
        };
      };

      let doNotMove = false;

      this.setDoNotMove = m => doNotMove = m;

      this.getDoNotMove = m => doNotMove;

      this.moveWindow = function (x, y, scale, rotate, delay) {
        if (this.getDoNotMove()) {
          console.log("we cannot move");
          return;
        }

        console.log("move to", x, y, "with scale, rotate, delay", scale, rotate, delay);
        currentScale = scale;
        currentRotate = rotate;
        winX = x;
        winY = y;
        console.log(x, y);
        setTimeout(() => {
          document.querySelector(".scale-container").style.transitionDuration = delay + "s";
          document.querySelector(".rotate-container").style.transitionDuration = delay + "s";
          universe.style.transitionDuration = delay + "s, " + delay + "s";
          setTimeout(() => {
            universe.style.left = -(x * 1440 - 1440 / 2) + "px";
            universe.style.top = -(y * 1080 - 1080 / 2) + "px";
            document.querySelector(".scale-container").style.transform = "scale(" + 1 / scale + ")";
            document.querySelector(".rotate-container").style.transform = "rotate(" + rotate + "deg)";
          }, 0);
        }, 0);
        return;
      };

      this.moveWindowRelative = function (dx, dy, dscale, drotate, delay) {
        this.moveWindow(winX + dx, winY + dy, currentScale + dscale, currentRotate + drotate, delay);
      };

      this.placeSlip = function (slip) {
        // console.log("debug Previous (slip)", slip);
        // let posX = 0.5;
        // let posY = 0.5;
        // let x=parseFloat(slip.getAttribute("pos-x")), y=parseFloat(slip.getAttribute("pos-y"));
        let scale = parseFloat(slip.getAttribute("scale")); // // console.log(slip);

        let slipScaleContainer = slip.querySelector(".slip-scale-container"); // let rotate = 0;

        scale = isNaN(scale) ? 1 : scale; // x = (isNaN(x) ? posX : x);
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

        slipScaleContainer.style.transform = "scale(" + scale + ")";
        slip.style.width = Math.max(slipScaleContainer.offsetWidth, 1440) * scale + "px";
        slip.style.height = Math.max(slipScaleContainer.offsetHeight, 1080) * scale + "px";
      };

      this.placeSlips = function () {
        // let posX = 0.5;
        // let posY = 0.5;
        let depth = function depth(elem) {
          console.log("debug depth (elem)", elem);
          let subslips = myQueryAll(elem, ".slip");
          console.log("debug depth (subslips)", elem);
          return 1 + subslips.map(depth).reduce((a, b) => Math.max(a, b), 0);
        };

        let rootDepth = depth(document.body);
        console.log("debug", rootDepth);

        for (let i = 0; i < rootDepth; i++) slips.forEach(this.placeSlip);
      };

      setTimeout(() => {
        this.placeSlips();
      }, 0);

      this.placeOpenWindow = function () {
        browserHeight = window.innerHeight;
        browserWidth = window.innerWidth;

        if (browserHeight / 3 < browserWidth / 4) {
          openWindowWidth = Math.floor(browserHeight * 4 / 3);
          openWindowHeight = browserHeight;
          openWindow.style.left = (window.innerWidth - openWindowWidth) / 2 + "px";
          openWindow.style.right = (window.innerWidth - openWindowWidth) / 2 + "px";
          openWindow.style.width = openWindowWidth + "px";
          openWindow.style.top = "0";
          openWindow.style.bottom = "0";
          openWindow.style.height = openWindowHeight + "px";
        } else {
          openWindowHeight = Math.floor(browserWidth * 3 / 4);
          openWindowWidth = browserWidth;
          openWindow.style.top = (window.innerHeight - openWindowHeight) / 2 + "px";
          openWindow.style.bottom = (window.innerHeight - openWindowHeight) / 2 + "px";
          openWindow.style.height = openWindowHeight + "px";
          openWindow.style.right = "0";
          openWindow.style.left = "0";
          openWindow.style.width = openWindowWidth + "px";
        }

        document.querySelector(".scale-container").style.transformOrigin = 1440 / 2 + "px " + 1080 / 2 + "px";
        document.querySelector(".rotate-container").style.transformOrigin = 1440 / 2 + "px " + 1080 / 2 + "px";
        document.querySelector(".format-container").style.transform = "scale(" + openWindowWidth / 1440 + ")";
        document.querySelector(".cpt-slip").style.right = parseInt(openWindow.style.left) + "px";
        document.querySelector(".cpt-slip").style.bottom = "0";
        document.querySelector(".cpt-slip").style.zIndex = "10";
      };

      this.placeOpenWindow();
      window.addEventListener("resize", ev => {
        this.placeOpenWindow();
        this.moveWindow(winX, winY, currentScale, currentRotate, 0);
      }); // Taken from https://selftaughtjs.com/algorithm-sundays-converting-roman-numerals
      // Use in showing roman numbers for slip number

      function counterToString(num, depth) {
        if (depth == 1 || depth > 3) return num.toString();
        let result = '';
        let decimal = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        let roman;
        if (depth == 0) roman = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];else roman = ["m", "cm", "d", "cd", "c", "xc", "l", "xl", "x", "ix", "v", "iv", "i"];

        for (var i = 0; i <= decimal.length; i++) {
          while (num % decimal[i] < num) {
            result += roman[i];
            num -= decimal[i];
          }
        }

        return result;
      }

      this.countersToString = counterList => {
        let res = '';
        res += counterToString(counterList[0] + 1, 0);

        for (let i = 1; i < counterList.length; i++) res += "." + counterToString(counterList[i] + 1, i);

        return res;
      };

      this.updateCounter = function () {
        let counters = stack.map(slip => slip.getActionIndex());
        document.querySelector(".cpt-slip").innerHTML = this.countersToString(counters);
      };

      this.next = () => {
        if (document.querySelector(".toc-slip").innerHTML == "") this.showToC(); // return true if and only if the stack changed

        let currentSlide = this.getCurrentSlip();
        let n = currentSlide.next();
        this.updateCounter();

        if (n instanceof Slip) {
          this.gotoSlip(n);
          this.push(n);
          this.next(); // this.showToC();

          return true;
        } else if (!n) {
          this.pop();
          let newCurrentSlip = this.getCurrentSlip();
          if (newCurrentSlip.nextStageNeedGoto()) this.gotoSlip(newCurrentSlip); // newCurrentSlip.incrIndex();

          if (stack.length > 1 || newCurrentSlip.getActionIndex() < newCurrentSlip.getMaxNext()) this.next();else this.gotoSlip(newCurrentSlip); // this.showToC();

          return true; // console.log(stack);
        } // this.showToC();


        return false;
      };

      this.nextSlip = function () {
        // Do this.next() untill the stack change
        while (!this.next()) {}
      };

      this.previous = () => {
        let currentSlip = this.getCurrentSlip(); // setDoNotMove(true);
        // let stage = currentSlip.previous2();
        // setDoNotMove(false);

        let n = currentSlip.previous(); // if(stage == "")

        console.log("debug previous (currentSlip, n)", currentSlip, n);

        if (n instanceof Slip) {
          while (n.getCurrentSubSlip() instanceof Slip) {
            this.push(n);
            n = n.getCurrentSubSlip();
          }

          this.push(n);
          this.gotoSlip(n); // this.showToC();

          this.updateCounter();
          return true;
        } else if (!n) {
          this.pop();
          let newCurrentSlide = this.getCurrentSlip(); // newCurrentSlide.incrIndex();

          if (stack.length > 1 || newCurrentSlide.getActionIndex() > -1) this.previous();else this.gotoSlip(newCurrentSlide); // console.log(stack);
          // this.showToC();

          this.updateCounter();
          return true;
        } // this.showToC();


        this.updateCounter();
        return false; // console.log("returned", n);
      };

      this.previousSlip = function () {
        // Do this.previous() untill the stack change
        while (!this.previous()) {}
      };

      this.getCoordinateInUniverse = function (elem) {
        console.log("debug getcoord elem", elem);

        let getCoordInParen = elem => {
          return {
            x: elem.offsetLeft,
            y: elem.offsetTop
          };
        };

        let globalScale = 1;

        let parseScale = function parseScale(transform) {
          if (transform == "none") return 1;
          return parseFloat(transform.split("(")[1].split(",")[0]);
        };

        let getCoordIter = elem => {
          console.log("debug getcoorditer elem", elem);
          let cInParent = getCoordInParen(elem);
          if (!elem.offsetParent) return {
            x: 0,
            y: 0,
            centerX: 0,
            centerY: 0,
            width: 0,
            height: 0,
            scale: 0
          };

          if (elem.offsetParent.classList.contains("universe")) {
            console.log("universe", cInParent);
            return cInParent;
          }

          let cParent = getCoordIter(elem.offsetParent);
          let style = window.getComputedStyle(elem.offsetParent); // console.log(style);

          let scale; // console.log("style", style.transform);
          // if (style.transform == "none")
          // 	scale = 1;
          // else
          // 	scale = parseFloat(style.transform.split("(")[1].split(",")[0]);

          scale = parseScale(style.transform); // console.log(style.transform);
          // console.log("scale", scale);
          // console.log("globalScale", globalScale);

          globalScale *= scale; // let scale = 1 ; // Has to parse/compute the scale, for now always 1
          // console.log("at step",  "cParent.x", cParent.x, "cInParen.x", cInParent.x, "scale", scale);

          return {
            x: cParent.x + cInParent.x * globalScale,
            y: cParent.y + cInParent.y * globalScale
          };
        };

        let c = getCoordIter(elem);
        let style = window.getComputedStyle(elem);
        let scale = parseScale(style.transform);
        globalScale *= scale;
        console.log("getCoord", {
          x: c.x / 1440 + 0.5,
          y: c.y / 1080 + 0.5
        }, "globalScale", globalScale, style.transform, scale);
        let ret = {
          x: c.x / 1440,
          y: c.y / 1080,
          centerX: c.x / 1440 + 0.5 * elem.offsetWidth / 1440 * globalScale,
          centerY: c.y / 1080 + 0.5 * elem.offsetHeight / 1080 * globalScale,
          width: elem.offsetWidth / 1440 * globalScale,
          height: elem.offsetHeight / 1080 * globalScale,
          scale: globalScale
        };
        console.log(ret);
        return ret; // return {x:c.x/1440+elem*globalScale*scale, y:c.y/1080+0.5*globalScale*scale, scale: globalScale*scale};
        // return {x: this.element.offsetLeft/1440+0.5, y:this.element.offsetTop/1080+0.5};
      };

      this.moveToElement = function (element, options) {
        let coord = this.getCoordinateInUniverse(element);
        let actualSize = {
          width: element.offsetWidth * coord.scale,
          height: element.offsetHeight * coord.scale
        };
        if (options) this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height) // coord.scale
        , 0, options.delay ? options.delay : 1);
      };

      this.gotoSlip = function (slip, options) {
        console.log("we goto slip", slip.element, this.getDoNotMove());
        options = options ? options : {};
        console.log("options is ", options);
        if (slip.element.classList.contains("slip")) setTimeout(() => {
          let coord = slip.findSlipCoordinate();

          if (typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined") {
            this.moveWindow(slip.currentX, slip.currentY, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
          } else {
            slip.currentX = coord.x;
            slip.currentY = coord.y;
            this.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, options.delay ? options.delay : slip.delay);
          }
        }, 0);else setTimeout(() => {
          console.log("debug slip element", slip.element);
          let coord = this.getCoordinateInUniverse(slip.element);
          this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height), 0, options.delay ? options.delay : slip.delay);
        }, 0);
      };

      let rootSlip = new Slip(root.id, "Presentation", [], this, {});
      let stack = [rootSlip]; // Stack Management:

      this.push = function (n) {
        stack.push(n);
        return;
      };

      this.pop = function () {
        let n = stack.pop();
        if (stack.length == 0) stack.push(n);
        return n;
      };

      this.getCurrentSlip = function () {
        return stack[stack.length - 1];
      };

      this.getSlipTree = function (slip) {
        slip = slip || rootSlip;
        if (slip instanceof Slip) return {
          name: slip.name,
          slip: slip,
          subslips: slip.getActionList().map(e => this.getSlipTree(e))
        };
        return {
          function: true
        };
      };

      this.goToState = function (state) {
        let iter = state => {
          if (state.length == 0) return;
          iter(state[0]);

          while (state[1].getActionIndex() < state[2]) this.next();
        };

        stack = [rootSlip];
        rootSlip.refreshAll();
        iter(state);
        this.gotoSlip(state[1]);
      };

      this.showToC = function () {
        console.log("debug showtoc");
        let toc = document.querySelector(".toc-slip"); // let innerHTML = "";

        let globalElem = document.createElement("div");
        let tree = this.getSlipTree(); // let before = true;

        let displayTree = (tree, stackWithNumbers) => {
          console.log("debug treee", tree);
          let containerElement = document.createElement("div");
          let nameElement = document.createElement("div"); // if(before)
          // 	nameElement.style.color = "blue";
          // else
          // 	nameElement.style.color = "yellow";
          // if(tree.slip == this.getCurrentSlip()) {
          // 	nameElement.style.color = "red";
          // 	before = false;
          // }

          nameElement.innerText = tree.slip.fullName ? tree.slip.fullName : tree.slip.name; //+ " (" + (tree.slip.getActionIndex()+1) + "/" + (tree.slip.getMaxNext()+1) + ")";

          containerElement.appendChild(nameElement); // innerHTML += "<div>"+tree.name+"</div>";

          if (tree.subslips.length > 0) {
            let ulElement = document.createElement("ul"); // innerHTML += "<ul>";

            tree.subslips.forEach((subtree, index) => {
              let newStackWithNumbers = [stackWithNumbers, tree.slip, index];
              let liElement = document.createElement("li"); // innerHTML += "<li>";

              if (subtree.function) {
                let toCounter = c => {
                  if (c.length == 0) return [];
                  return toCounter(c[0]).concat([c[2]]);
                };

                liElement.innerText = this.countersToString(toCounter(newStackWithNumbers)); //			liElement.innerText = ""+(index+1);

                liElement.classList.add("toc-function");
              } else liElement.appendChild(displayTree(subtree, newStackWithNumbers));

              liElement.addEventListener("click", ev => {
                if (ev.target == liElement) {
                  this.goToState(newStackWithNumbers);
                  console.log("newstack", newStackWithNumbers);
                }
              });
              ulElement.appendChild(liElement); // innerHTML += "</li>";
            });
            containerElement.appendChild(ulElement);
            tree.slip.setTocElem(containerElement); // innerHTML += "</ul>";
          }

          console.log("debug tree, will return", containerElement); // containerElement.addEventListener("click", () => { console.log(stackWithNumbers);});

          return containerElement;
        };

        toc.innerHTML = ""; // toc.innerHTML = innerHTML;

        toc.appendChild(displayTree(tree, []));
      }; // this.getRootSlip = () => rootSlip;


      this.setRootSlip = root => {
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
    }

    function IController (ng) {
      let engine = ng;

      this.getEngine = () => this.engine;

      this.setEngine = ng => this.engine = ng; // let mainSlip = mainS;
      // this.getMainSlip = () => mainSlip;
      // this.setMainSlip = (slip) => mainSlip = slip;


      let speedMove = 1;
      document.addEventListener("keypress", ev => {
        if (ev.key == "f") {
          speedMove = (speedMove + 4) % 30 + 1;
        }

        if (ev.key == "r") {
          engine.getCurrentSlip().refresh();
        }

        if (ev.key == "#") {
          document.querySelectorAll(".slip").forEach(slip => {
            slip.style.zIndex = "-1";
          });
          document.querySelectorAll(".background-canvas").forEach(canvas => {
            canvas.style.zIndex = "1";
          });
        }
      });
      document.addEventListener("keydown", ev => {
        let openWindowHeight = engine.getOpenWindowHeight();
        let openWindowWidth = engine.getOpenWindowWidth();

        if (ev.key == "l") {
          engine.moveWindowRelative(0, speedMove / openWindowHeight, 0, 0, 0.1);
        } // Bas


        if (ev.key == "o") {
          engine.moveWindowRelative(0, -speedMove / openWindowHeight, 0, 0, 0.1);
        } // Haut


        if (ev.key == "k") {
          engine.moveWindowRelative(-speedMove / openWindowWidth, 0, 0, 0, 0.1);
        } // Gauche


        if (ev.key == "m") {
          engine.moveWindowRelative(speedMove / openWindowWidth, 0, 0, 0, 0.1);
        } // Droite


        if (ev.key == "i") {
          engine.moveWindowRelative(0, 0, 0, 1, 0.1);
        } // Rotate 


        if (ev.key == "p") {
          engine.moveWindowRelative(0, 0, 0, -1, 0.1);
        } // Unrotate


        if (ev.key == "z") {
          engine.moveWindowRelative(0, 0, 0.01, 0, 0.1);
        } // Zoom


        if (ev.key == "Z") {
          engine.moveWindowRelative(0, 0, -0.01, 0, 0.1);
        } // Unzoom


        if (ev.key == "T") {
          engine.showToC(); // document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none"; 
        }

        if (ev.key == "t") {
          // engine.showToC();
          document.querySelector(".toc-slip").style.display = document.querySelector(".toc-slip").style.display == "none" ? "block" : "none";
        }

        if (ev.key == "ArrowRight") {
          console.log(ev);
          if (ev.shiftKey) engine.nextSlip();else engine.next();
        } else if (ev.key == "ArrowLeft") {
          if (ev.shiftKey) engine.previousSlip();else engine.previous();
        } else if (ev.key == "ArrowUp") {
          engine.pop();
        }
      });
    }

    function Slip$1(name, fullName, actionL, ng, options) {
      // ******************************
      // Action List
      // ******************************
      this.generateActionList = function () {
        console.log("debug generateactionlist", this.name);
        let newActionList = [];
        this.queryAll(".slip[enter-at]").forEach(slip => {
          console.log("new slip with ", slip, null, null, ng, {});
          newActionList[slip.getAttribute("enter-at")] = new Slip$1(slip, "", [], ng, {});
        });
        return newActionList;
      };

      this.addSubSlips = function () {
        console.log("debug generateactionlist", this.name);
        let newActionList = [];
        this.queryAll(".slip[enter-at]").forEach(slip => {
          console.log("new slip with ", slip, null, null, ng, {});
          this.setNthAction(slip.getAttribute("enter-at"), new Slip$1(slip, "", [], ng, {}));
        });
        return newActionList;
      };

      let actionList = actionL; // || this.generateActionList();

      this.setAction = actionL => {
        actionList = actionL;
      };

      this.getActionList = () => {
        let ret = [];

        for (let i = 0; i <= this.getMaxNext(); i++) {
          if (this.pauseSlipList[i] instanceof Slip$1) ret[i] = this.pauseSlipList[i];else if (typeof actionList[i] == "function" || actionList[i] instanceof Slip$1) ret[i] = actionList[i];else ret[i] = () => {};
        }

        return ret;
      };

      this.setNthAction = (n, action) => {
        actionList[n] = action;
      };

      this.getCurrentSubSlip = () => {
        if (actionList[this.getActionIndex()] instanceof Slip$1) return actionList[this.getActionIndex()];
        if (this.pauseSlipList[this.getActionIndex()] instanceof Slip$1) return this.pauseSlipList[this.getActionIndex()];
        return false;
      };

      this.nextStageNeedGoto = () => {
        if (actionList[this.getActionIndex() + 1] instanceof Slip$1) return false;
        if (this.pauseSlipList[this.getActionIndex() + 1] instanceof Slip$1) return false;
        if (this.getActionIndex() >= this.getMaxNext()) return false;
        return true;
      };

      this.getSubSlipList = function () {
        return actionList.filter(action => action instanceof Slip$1);
      }; // ******************************
      // Action Index
      // ******************************


      let actionIndex = -1;

      this.setActionIndex = actionI => actionIndex = actionI;

      this.getActionIndex = () => actionIndex;

      this.getMaxNext = () => {
        if (this.maxNext) return this.maxNext;
        let maxTemp = actionList.length;
        ["mk-visible-at", "mk-hidden-at", "mk-emphasize-at", "mk-unemphasize-at", "emphasize-at", "chg-visib-at", "up-at", "down-at", "center-at", "static-at", "exec-at"].forEach(attr => {
          this.queryAll("*[" + attr + "]").forEach(elem => {
            elem.getAttribute(attr).split(" ").forEach(strMax => {
              maxTemp = Math.max(Math.abs(parseInt(strMax)), maxTemp);
            });
          });
        });
        let sumArray = this.queryAll("[pause], [step], [auto-enter], [immediate-enter]").map(elem => {
          if (elem.hasAttribute("pause") && elem.getAttribute("pause") != "") return parseInt(elem.getAttribute("pause"));
          if (elem.hasAttribute("step") && elem.getAttribute("step") != "") return parseInt(elem.getAttribute("step"));
          return 1;
        });
        maxTemp = Math.max(maxTemp, sumArray.reduce((a, b) => a + b, 0));
        this.maxNext = maxTemp;
        return maxTemp;
      }; // ******************************
      // Queries
      // ******************************


      this.queryAll = quer => {
        return myQueryAll(this.element, quer); // let allElem = Array.from(this.element.querySelectorAll(quer));
        // let other = Array.from(this.element.querySelectorAll("#"+this.name+" .slip "+quer));
        // return allElem.filter(value => !other.includes(value));
      };

      this.query = quer => {
        return this.queryAll(quer)[0];
      };

      this.findSubslipByID = id => {
        let goodSubslip = this.getSubSlipList().find(subslip => {
          if (subslip.name == id) return 1;
          return subslip.findSubslipByID(id);
        });
        if (!goodSubslip) return false;
        if (goodSubslip.name == id) return goodSubslip;
        return goodSubslip.findSubslipByID(id);
      }; // ******************************
      // Coordinates
      // ******************************


      this.findSlipCoordinate = () => {
        // rename to getCoordInUniverse
        let coord = engine.getCoordinateInUniverse(this.element);
        console.log("debug findslipcoordinate", coord);
        coord.scale *= this.scale;
        coord.y = coord.y + 0.5 * coord.scale;
        coord.x = coord.centerX;
        console.log("debug findslipcoordinate", coord);
        return coord;
      }; // ******************************
      // Pause functions
      // ******************************


      this.updatePauseAncestors = () => {
        this.queryAll(".pauseAncestor").forEach(elem => {
          elem.classList.remove("pauseAncestor");
        });
        let pause = this.query("[pause]");

        while (pause && !pause.classList.contains("slip")) {
          pause.classList.add("pauseAncestor");
          pause = pause.parentElement;
        }
      };

      this.incrPause = () => {
        let pause = this.query("[pause], [auto-enter]:not([auto-enter=\"0\"]), [immediate-enter]:not([immediate-enter=\"0\"]), [step]"); // let pause = this.query("[pause]");

        if (pause) {
          console.log("pause is", this.name, pause);

          if (pause.hasAttribute("step")) {
            if (!pause.getAttribute("step")) pause.setAttribute("step", 1);
            let d = pause.getAttribute("step");

            if (d <= 1) {
              pause.removeAttribute("step");
            } else pause.setAttribute("step", d - 1);
          }

          if (pause.hasAttribute("auto-enter")) {
            pause.setAttribute("auto-enter", 0);
          }

          if (pause.hasAttribute("immediate-enter")) {
            pause.setAttribute("immediate-enter", 0);
          }

          if (pause.hasAttribute("pause")) {
            if (!pause.getAttribute("pause")) pause.setAttribute("pause", 1);
            let d = pause.getAttribute("pause");

            if (d <= 1) {
              pause.removeAttribute("pause");

              if (pause.hasAttribute("down-at-unpause")) {
                if (pause.getAttribute("down-at-unpause") == "") this.moveDownTo(pause, 1);else this.moveDownTo("#" + pause.getAttribute("down-at-unpause"), 1);
              }

              if (pause.hasAttribute("up-at-unpause")) {
                if (pause.getAttribute("up-at-unpause") == "") this.moveUpTo(pause, 1);else this.moveUpTo("#" + pause.getAttribute("up-at-unpause"), 1);
              }

              if (pause.hasAttribute("center-at-unpause")) if (pause.getAttribute("center-at-unpause") == "") this.moveCenterTo(pause, 1);else this.moveCenterTo("#" + pause.getAttribute("center-at-unpause"), 1);
            } else pause.setAttribute("pause", d - 1);

            this.updatePauseAncestors();
          }
        }
      }; // ******************************
      // Next functions
      // ******************************


      this.doAttributes = () => {
        this.queryAll("*[mk-hidden-at]").forEach(elem => {
          let hiddenAt = elem.getAttribute("mk-hidden-at").split(" ").map(str => parseInt(str));
          if (hiddenAt.includes(actionIndex)) elem.style.opacity = "0";
        });
        this.queryAll("*[mk-visible-at]").forEach(elem => {
          let visibleAt = elem.getAttribute("mk-visible-at").split(" ").map(str => parseInt(str));
          if (visibleAt.includes(actionIndex)) elem.style.opacity = "1";
        });
        this.queryAll("*[mk-emphasize-at]").forEach(elem => {
          let emphAt = elem.getAttribute("mk-emphasize-at").split(" ").map(str => parseInt(str));
          if (emphAt.includes(actionIndex)) elem.classList.add("emphasize");
        });
        this.queryAll("*[mk-unemphasize-at]").forEach(elem => {
          let unemphAt = elem.getAttribute("mk-unemphasize-at").split(" ").map(str => parseInt(str));
          if (unemphAt.includes(actionIndex)) elem.classList.remove("emphasize");
        });
        this.queryAll("*[emphasize-at]").forEach(elem => {
          let emphAt = elem.getAttribute("emphasize-at").split(" ").map(str => parseInt(str));
          if (emphAt.includes(actionIndex)) elem.classList.add("emphasize");else elem.classList.remove("emphasize");
        });
        this.queryAll("*[chg-visib-at]").forEach(elem => {
          let visibAt = elem.getAttribute("chg-visib-at").split(" ").map(str => parseInt(str));
          if (visibAt.includes(actionIndex)) elem.style.opacity = "1";
          if (visibAt.includes(-actionIndex)) elem.style.opacity = "0";
        });
        this.queryAll("*[static-at]").forEach(elem => {
          let staticAt = elem.getAttribute("static-at").split(" ").map(str => parseInt(str));

          if (staticAt.includes(-actionIndex)) {
            elem.style.position = "absolute";
            elem.style.visibility = "hidden";
          }

          if (staticAt.includes(actionIndex)) {
            elem.style.position = "static";
            elem.style.visibility = "visible";
          }
        });
        this.queryAll("*[down-at]").forEach(elem => {
          let goDownTo = elem.getAttribute("down-at").split(" ").map(str => parseInt(str));
          if (goDownTo.includes(actionIndex)) this.moveDownTo(elem, 1);
        });
        this.queryAll("*[up-at]").forEach(elem => {
          let goTo = elem.getAttribute("up-at").split(" ").map(str => parseInt(str));
          if (goTo.includes(actionIndex)) this.moveUpTo(elem, 1);
        });
        this.queryAll("*[center-at]").forEach(elem => {
          let goDownTo = elem.getAttribute("center-at").split(" ").map(str => parseInt(str));
          if (goDownTo.includes(actionIndex)) this.moveCenterTo(elem, 1);
        });
        this.queryAll("*[exec-at]").forEach(elem => {
          let toExec = elem.getAttribute("exec-at").split(" ").map(str => parseInt(str));
          if (toExec.includes(actionIndex)) new Function("slip", elem.innerHTML)(this);
        });
      };

      this.incrIndex = () => {
        console.log("incrIndex", this.name);
        actionIndex = actionIndex + 1;
        this.doAttributes();
        if (actionIndex > 0) this.incrPause();
        this.updateToC();
      };

      this.next = function () {
        if (actionIndex >= this.getMaxNext()) return false;
        this.incrIndex();

        if (typeof actionList[actionIndex] == "function") {
          actionList[actionIndex](this);
        }

        if (actionList[actionIndex] instanceof Slip$1) {
          return actionList[actionIndex];
        }

        if (this.pauseSlipList[actionIndex] instanceof Slip$1) return this.pauseSlipList[actionIndex]; // let nextSlip = this.query("[pause], [auto-enter]");
        // if(nextSlip.hasAttribute("auto-enter"))
        //     return 

        return true;
      };

      this.previous = () => {
        let savedActionIndex = this.getActionIndex();
        this.getEngine().setDoNotMove(true);
        console.log("gotoslip: we call doRefresh", this.doRefresh());
        if (savedActionIndex == -1) return false;
        let toReturn;

        while (this.getActionIndex() < savedActionIndex - 2) toReturn = this.next();

        if (!this.nextStageNeedGoto()) this.getEngine().setDoNotMove(false);

        while (this.getActionIndex() < savedActionIndex - 1) toReturn = this.next();

        this.getEngine().setDoNotMove(false);
        return toReturn; // return this.next;
      }; // ******************************
      // ToC functions
      // ******************************


      this.setTocElem = tocElem => {
        this.tocElem = tocElem;
      };

      this.updateToC = () => {
        if (!this.tocElem) return;
        if (!this.ToCList) this.ToCList = myQueryAll(this.tocElem, "li", "li");
        let i;

        for (i = 0; i < this.getActionIndex(); i++) {
          this.ToCList[i].classList.remove("before", "after", "current");
          this.ToCList[i].classList.add("before");
        }

        if (i <= this.getActionIndex()) {
          this.ToCList[i].classList.remove("before", "after", "current");
          this.ToCList[i].classList.add("current");
          i++;
        }

        for (i; i <= this.getMaxNext(); i++) {
          this.ToCList[i].classList.remove("before", "after", "current");
          this.ToCList[i].classList.add("after");
        }
      };

      this.firstVisit = () => {
        this.updateToC();
        if (options.firstVisit) options.firstVisit(this);
      };

      this.init = () => {
        this.queryAll("*[chg-visib-at]").forEach(elem => {
          elem.style.opacity = "0";
        });
        this.queryAll("*[static-at]").forEach(elem => {
          elem.style.position = "absolute";
          elem.style.visibility = "hidden";
        });
        this.doAttributes();
        this.updatePauseAncestors();
        if (options.init) options.init(this);
      }; // ******************************
      // Refreshes
      // ******************************


      this.refresh = () => {
        if (actionList[actionIndex] instanceof Slip$1) actionList[actionIndex].refresh();else this.doRefresh();
      };

      this.refreshAll = () => {
        actionList.filter(elem => elem instanceof Slip$1).forEach(subslip => {
          subslip.refreshAll();
        });
        this.pauseSlipList.filter(elem => elem instanceof Slip$1).forEach(subslip => {
          subslip.refreshAll();
        });
        this.doRefresh();
      };

      this.doRefresh = () => {
        console.log("gotoslip: doRefresh has been called");
        this.setActionIndex(-1);
        let subSlipList = myQueryAll(this.element, ".slip");
        console.log("mmdebug", clonedElement);
        let clone = clonedElement.cloneNode(true);
        replaceSubslips(clone, subSlipList);
        this.element.replaceWith(clone);
        this.element = clone;
        this.init();
        this.firstVisit();
        delete this.currentX;
        delete this.currentY;
        engine.gotoSlip(this);
      }; // ******************************
      // Movement and hide/show
      // ******************************


      this.moveUpTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0.0125;
          let coord = this.findSlipCoordinate();
          let d = (elem.offsetTop / 1080 - offset) * coord.scale;
          this.currentX = coord.x;
          this.currentY = coord.y + d;
          engine.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.moveDownTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0.0125;
          let coord = this.findSlipCoordinate();
          let d = ((elem.offsetTop + elem.offsetHeight) / 1080 - 1 + offset) * coord.scale;
          this.currentX = coord.x;
          this.currentY = coord.y + d;
          engine.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.moveCenterTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0;
          let coord = this.findSlipCoordinate();
          let d = ((elem.offsetTop + elem.offsetHeight / 2) / 1080 - 1 / 2 + offset) * coord.scale;
          this.currentX = coord.x;
          this.currentY = coord.y + d;
          engine.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.reveal = selector => {
        this.query(selector).style.opacity = "1";
      };

      this.revealAll = selector => {
        this.queryAll(selector).forEach(elem => {
          elem.style.opacity = "1";
        });
      };

      this.hide = selector => {
        this.query(selector).style.opacity = "0";
      };

      this.hideAll = selector => {
        this.queryAll(selector).forEach(elem => {
          elem.style.opacity = "0";
        });
      }; // ******************************
      // Initialisation of the object
      // ******************************
      // names    


      this.fullName = fullName;
      this.name = typeof name == "string" ? name : name.id;
      console.log("this name is ", this.name); // engine

      let engine = ng;

      this.getEngine = () => engine;

      this.setEngine = ng => engine = ng; // element


      this.element = typeof name == "string" ? document.querySelector("#" + name) : name; // clonedElement

      let clonedElement;
      if (typeof MathJax != "undefined") MathJax.startup.promise.then(() => {
        setTimeout(() => {
          clonedElement = cloneNoSubslip(this.element);
        }, 0);
      });else setTimeout(() => {
        clonedElement = cloneNoSubslip(this.element);
      }, 0);

      this.getCloned = () => clonedElement;

      this.setCloned = c => clonedElement = c; // scale, rotate, delay


      this.scale = parseFloat(this.element.getAttribute("scale"));
      if (typeof this.scale == "undefined" || isNaN(this.scale)) this.scale = 1;
      this.rotate = parseFloat(this.element.getAttribute("rotate")) || 0;
      this.delay = isNaN(parseFloat(this.element.getAttribute("delay"))) ? 0 : parseFloat(this.element.getAttribute("delay")); // coord

      let coord = this.findSlipCoordinate();
      console.log(coord);
      this.x = coord.x;
      this.y = coord.y; // Preparing the slip

      this.init(this, engine); // Adding "enter-at" subslips

      this.addSubSlips(); // Adding "paused-flow" subslips

      this.generatePauseFlowSlipList = function () {
        let slipList = [];
        let bla = this.queryAll("[pause], [step], [auto-enter], [immediate-enter]");
        let step = 1;
        bla.forEach(elem => {
          console.log("debug generatePauseFlowsliplist", elem, step);

          if (elem.hasAttribute("auto-enter")) {
            slipList[step] = new Slip$1(elem, elem.getAttribute("toc-title") || "", [], ng, {});
            step++;
          }

          if (elem.hasAttribute("immediate-enter")) {
            // the slip is entered before the pause
            slipList[step - 1] = new Slip$1(elem, elem.getAttribute("toc-title") || "", [], ng, {});
            step++;
          }

          if (elem.hasAttribute("step")) {
            console.log("debug generatePauseFlowsliplist1", elem, step);
            step += parseInt(elem.getAttribute("step")) || 1;
            console.log("debug generatePauseFlowsliplist2", elem, step);
          }

          if (elem.hasAttribute("pause")) {
            console.log("debug generatePauseFlowsliplist1", elem, step);
            step += parseInt(elem.getAttribute("pause")) || 1;
            console.log("debug generatePauseFlowsliplist1", elem, step);
          }
        });
        return slipList;
      };

      this.pauseSlipList = this.generatePauseFlowSlipList(); // this.pauseSlipList = this.queryAll("[pause], [step], [auto-enter]").map((elem) => {
      // 	if(elem.hasAttribute("auto-enter"))
      // 	    return new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
      // 	return null;
      // });
    }

    // import "./css/theorem.css";

    /**
     * Allows slip-js to be used as a module
     */

    const Engine = IEngine;
    const Controller = IController;
    const Slip$2 = Slip$1;
    const Util = IUtil;
    /**
     * Allows slip-js to be used as simple CDN-included file
     */

    window.Engine = IEngine;
    window.Controller = IController;
    window.Slip = Slip$1;
    window.Util = IUtil;

    exports.Controller = Controller;
    exports.Engine = Engine;
    exports.Slip = Slip$2;
    exports.Util = Util;

    return exports;

}({}));
//# sourceMappingURL=slip-lib.cdn.js.map
