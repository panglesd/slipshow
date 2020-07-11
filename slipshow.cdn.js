var Slipshow = (function (exports) {
    'use strict';

    let myQueryAll = (root, selector, avoid) => {
      avoid = avoid || "slip-slip";
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
        if (child.tagName && child.tagName == "SLIP-SLIP") {
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

    function createCommonjsModule(fn, module) {
    	return module = { exports: {} }, fn(module, module.exports), module.exports;
    }

    var hammer = createCommonjsModule(function (module) {
      /*! Hammer.JS - v2.0.7 - 2016-04-22
       * http://hammerjs.github.io/
       *
       * Copyright (c) 2016 Jorik Tangelder;
       * Licensed under the MIT license */
      (function (window, document, exportName, undefined$1) {

        var VENDOR_PREFIXES = ['', 'webkit', 'Moz', 'MS', 'ms', 'o'];
        var TEST_ELEMENT = document.createElement('div');
        var TYPE_FUNCTION = 'function';
        var round = Math.round;
        var abs = Math.abs;
        var now = Date.now;
        /**
         * set a timeout with a given scope
         * @param {Function} fn
         * @param {Number} timeout
         * @param {Object} context
         * @returns {number}
         */

        function setTimeoutContext(fn, timeout, context) {
          return setTimeout(bindFn(fn, context), timeout);
        }
        /**
         * if the argument is an array, we want to execute the fn on each entry
         * if it aint an array we don't want to do a thing.
         * this is used by all the methods that accept a single and array argument.
         * @param {*|Array} arg
         * @param {String} fn
         * @param {Object} [context]
         * @returns {Boolean}
         */


        function invokeArrayArg(arg, fn, context) {
          if (Array.isArray(arg)) {
            each(arg, context[fn], context);
            return true;
          }

          return false;
        }
        /**
         * walk objects and arrays
         * @param {Object} obj
         * @param {Function} iterator
         * @param {Object} context
         */


        function each(obj, iterator, context) {
          var i;

          if (!obj) {
            return;
          }

          if (obj.forEach) {
            obj.forEach(iterator, context);
          } else if (obj.length !== undefined$1) {
            i = 0;

            while (i < obj.length) {
              iterator.call(context, obj[i], i, obj);
              i++;
            }
          } else {
            for (i in obj) {
              obj.hasOwnProperty(i) && iterator.call(context, obj[i], i, obj);
            }
          }
        }
        /**
         * wrap a method with a deprecation warning and stack trace
         * @param {Function} method
         * @param {String} name
         * @param {String} message
         * @returns {Function} A new function wrapping the supplied method.
         */


        function deprecate(method, name, message) {
          var deprecationMessage = 'DEPRECATED METHOD: ' + name + '\n' + message + ' AT \n';
          return function () {
            var e = new Error('get-stack-trace');
            var stack = e && e.stack ? e.stack.replace(/^[^\(]+?[\n$]/gm, '').replace(/^\s+at\s+/gm, '').replace(/^Object.<anonymous>\s*\(/gm, '{anonymous}()@') : 'Unknown Stack Trace';
            var log = window.console && (window.console.warn || window.console.log);

            if (log) {
              log.call(window.console, deprecationMessage, stack);
            }

            return method.apply(this, arguments);
          };
        }
        /**
         * extend object.
         * means that properties in dest will be overwritten by the ones in src.
         * @param {Object} target
         * @param {...Object} objects_to_assign
         * @returns {Object} target
         */


        var assign;

        if (typeof Object.assign !== 'function') {
          assign = function assign(target) {
            if (target === undefined$1 || target === null) {
              throw new TypeError('Cannot convert undefined or null to object');
            }

            var output = Object(target);

            for (var index = 1; index < arguments.length; index++) {
              var source = arguments[index];

              if (source !== undefined$1 && source !== null) {
                for (var nextKey in source) {
                  if (source.hasOwnProperty(nextKey)) {
                    output[nextKey] = source[nextKey];
                  }
                }
              }
            }

            return output;
          };
        } else {
          assign = Object.assign;
        }
        /**
         * extend object.
         * means that properties in dest will be overwritten by the ones in src.
         * @param {Object} dest
         * @param {Object} src
         * @param {Boolean} [merge=false]
         * @returns {Object} dest
         */


        var extend = deprecate(function extend(dest, src, merge) {
          var keys = Object.keys(src);
          var i = 0;

          while (i < keys.length) {
            if (!merge || merge && dest[keys[i]] === undefined$1) {
              dest[keys[i]] = src[keys[i]];
            }

            i++;
          }

          return dest;
        }, 'extend', 'Use `assign`.');
        /**
         * merge the values from src in the dest.
         * means that properties that exist in dest will not be overwritten by src
         * @param {Object} dest
         * @param {Object} src
         * @returns {Object} dest
         */

        var merge = deprecate(function merge(dest, src) {
          return extend(dest, src, true);
        }, 'merge', 'Use `assign`.');
        /**
         * simple class inheritance
         * @param {Function} child
         * @param {Function} base
         * @param {Object} [properties]
         */

        function inherit(child, base, properties) {
          var baseP = base.prototype,
              childP;
          childP = child.prototype = Object.create(baseP);
          childP.constructor = child;
          childP._super = baseP;

          if (properties) {
            assign(childP, properties);
          }
        }
        /**
         * simple function bind
         * @param {Function} fn
         * @param {Object} context
         * @returns {Function}
         */


        function bindFn(fn, context) {
          return function boundFn() {
            return fn.apply(context, arguments);
          };
        }
        /**
         * let a boolean value also be a function that must return a boolean
         * this first item in args will be used as the context
         * @param {Boolean|Function} val
         * @param {Array} [args]
         * @returns {Boolean}
         */


        function boolOrFn(val, args) {
          if (typeof val == TYPE_FUNCTION) {
            return val.apply(args ? args[0] || undefined$1 : undefined$1, args);
          }

          return val;
        }
        /**
         * use the val2 when val1 is undefined
         * @param {*} val1
         * @param {*} val2
         * @returns {*}
         */


        function ifUndefined(val1, val2) {
          return val1 === undefined$1 ? val2 : val1;
        }
        /**
         * addEventListener with multiple events at once
         * @param {EventTarget} target
         * @param {String} types
         * @param {Function} handler
         */


        function addEventListeners(target, types, handler) {
          each(splitStr(types), function (type) {
            target.addEventListener(type, handler, false);
          });
        }
        /**
         * removeEventListener with multiple events at once
         * @param {EventTarget} target
         * @param {String} types
         * @param {Function} handler
         */


        function removeEventListeners(target, types, handler) {
          each(splitStr(types), function (type) {
            target.removeEventListener(type, handler, false);
          });
        }
        /**
         * find if a node is in the given parent
         * @method hasParent
         * @param {HTMLElement} node
         * @param {HTMLElement} parent
         * @return {Boolean} found
         */


        function hasParent(node, parent) {
          while (node) {
            if (node == parent) {
              return true;
            }

            node = node.parentNode;
          }

          return false;
        }
        /**
         * small indexOf wrapper
         * @param {String} str
         * @param {String} find
         * @returns {Boolean} found
         */


        function inStr(str, find) {
          return str.indexOf(find) > -1;
        }
        /**
         * split string on whitespace
         * @param {String} str
         * @returns {Array} words
         */


        function splitStr(str) {
          return str.trim().split(/\s+/g);
        }
        /**
         * find if a array contains the object using indexOf or a simple polyFill
         * @param {Array} src
         * @param {String} find
         * @param {String} [findByKey]
         * @return {Boolean|Number} false when not found, or the index
         */


        function inArray(src, find, findByKey) {
          if (src.indexOf && !findByKey) {
            return src.indexOf(find);
          } else {
            var i = 0;

            while (i < src.length) {
              if (findByKey && src[i][findByKey] == find || !findByKey && src[i] === find) {
                return i;
              }

              i++;
            }

            return -1;
          }
        }
        /**
         * convert array-like objects to real arrays
         * @param {Object} obj
         * @returns {Array}
         */


        function toArray(obj) {
          return Array.prototype.slice.call(obj, 0);
        }
        /**
         * unique array with objects based on a key (like 'id') or just by the array's value
         * @param {Array} src [{id:1},{id:2},{id:1}]
         * @param {String} [key]
         * @param {Boolean} [sort=False]
         * @returns {Array} [{id:1},{id:2}]
         */


        function uniqueArray(src, key, sort) {
          var results = [];
          var values = [];
          var i = 0;

          while (i < src.length) {
            var val = key ? src[i][key] : src[i];

            if (inArray(values, val) < 0) {
              results.push(src[i]);
            }

            values[i] = val;
            i++;
          }

          if (sort) {
            if (!key) {
              results = results.sort();
            } else {
              results = results.sort(function sortUniqueArray(a, b) {
                return a[key] > b[key];
              });
            }
          }

          return results;
        }
        /**
         * get the prefixed property
         * @param {Object} obj
         * @param {String} property
         * @returns {String|Undefined} prefixed
         */


        function prefixed(obj, property) {
          var prefix, prop;
          var camelProp = property[0].toUpperCase() + property.slice(1);
          var i = 0;

          while (i < VENDOR_PREFIXES.length) {
            prefix = VENDOR_PREFIXES[i];
            prop = prefix ? prefix + camelProp : property;

            if (prop in obj) {
              return prop;
            }

            i++;
          }

          return undefined$1;
        }
        /**
         * get a unique id
         * @returns {number} uniqueId
         */


        var _uniqueId = 1;

        function uniqueId() {
          return _uniqueId++;
        }
        /**
         * get the window object of an element
         * @param {HTMLElement} element
         * @returns {DocumentView|Window}
         */


        function getWindowForElement(element) {
          var doc = element.ownerDocument || element;
          return doc.defaultView || doc.parentWindow || window;
        }

        var MOBILE_REGEX = /mobile|tablet|ip(ad|hone|od)|android/i;
        var SUPPORT_TOUCH = ('ontouchstart' in window);
        var SUPPORT_POINTER_EVENTS = prefixed(window, 'PointerEvent') !== undefined$1;
        var SUPPORT_ONLY_TOUCH = SUPPORT_TOUCH && MOBILE_REGEX.test(navigator.userAgent);
        var INPUT_TYPE_TOUCH = 'touch';
        var INPUT_TYPE_PEN = 'pen';
        var INPUT_TYPE_MOUSE = 'mouse';
        var INPUT_TYPE_KINECT = 'kinect';
        var COMPUTE_INTERVAL = 25;
        var INPUT_START = 1;
        var INPUT_MOVE = 2;
        var INPUT_END = 4;
        var INPUT_CANCEL = 8;
        var DIRECTION_NONE = 1;
        var DIRECTION_LEFT = 2;
        var DIRECTION_RIGHT = 4;
        var DIRECTION_UP = 8;
        var DIRECTION_DOWN = 16;
        var DIRECTION_HORIZONTAL = DIRECTION_LEFT | DIRECTION_RIGHT;
        var DIRECTION_VERTICAL = DIRECTION_UP | DIRECTION_DOWN;
        var DIRECTION_ALL = DIRECTION_HORIZONTAL | DIRECTION_VERTICAL;
        var PROPS_XY = ['x', 'y'];
        var PROPS_CLIENT_XY = ['clientX', 'clientY'];
        /**
         * create new input type manager
         * @param {Manager} manager
         * @param {Function} callback
         * @returns {Input}
         * @constructor
         */

        function Input(manager, callback) {
          var self = this;
          this.manager = manager;
          this.callback = callback;
          this.element = manager.element;
          this.target = manager.options.inputTarget; // smaller wrapper around the handler, for the scope and the enabled state of the manager,
          // so when disabled the input events are completely bypassed.

          this.domHandler = function (ev) {
            if (boolOrFn(manager.options.enable, [manager])) {
              self.handler(ev);
            }
          };

          this.init();
        }

        Input.prototype = {
          /**
           * should handle the inputEvent data and trigger the callback
           * @virtual
           */
          handler: function handler() {},

          /**
           * bind the events
           */
          init: function init() {
            this.evEl && addEventListeners(this.element, this.evEl, this.domHandler);
            this.evTarget && addEventListeners(this.target, this.evTarget, this.domHandler);
            this.evWin && addEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
          },

          /**
           * unbind the events
           */
          destroy: function destroy() {
            this.evEl && removeEventListeners(this.element, this.evEl, this.domHandler);
            this.evTarget && removeEventListeners(this.target, this.evTarget, this.domHandler);
            this.evWin && removeEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
          }
        };
        /**
         * create new input type manager
         * called by the Manager constructor
         * @param {Hammer} manager
         * @returns {Input}
         */

        function createInputInstance(manager) {
          var Type;
          var inputClass = manager.options.inputClass;

          if (inputClass) {
            Type = inputClass;
          } else if (SUPPORT_POINTER_EVENTS) {
            Type = PointerEventInput;
          } else if (SUPPORT_ONLY_TOUCH) {
            Type = TouchInput;
          } else if (!SUPPORT_TOUCH) {
            Type = MouseInput;
          } else {
            Type = TouchMouseInput;
          }

          return new Type(manager, inputHandler);
        }
        /**
         * handle input events
         * @param {Manager} manager
         * @param {String} eventType
         * @param {Object} input
         */


        function inputHandler(manager, eventType, input) {
          var pointersLen = input.pointers.length;
          var changedPointersLen = input.changedPointers.length;
          var isFirst = eventType & INPUT_START && pointersLen - changedPointersLen === 0;
          var isFinal = eventType & (INPUT_END | INPUT_CANCEL) && pointersLen - changedPointersLen === 0;
          input.isFirst = !!isFirst;
          input.isFinal = !!isFinal;

          if (isFirst) {
            manager.session = {};
          } // source event is the normalized value of the domEvents
          // like 'touchstart, mouseup, pointerdown'


          input.eventType = eventType; // compute scale, rotation etc

          computeInputData(manager, input); // emit secret event

          manager.emit('hammer.input', input);
          manager.recognize(input);
          manager.session.prevInput = input;
        }
        /**
         * extend the data with some usable properties like scale, rotate, velocity etc
         * @param {Object} manager
         * @param {Object} input
         */


        function computeInputData(manager, input) {
          var session = manager.session;
          var pointers = input.pointers;
          var pointersLength = pointers.length; // store the first input to calculate the distance and direction

          if (!session.firstInput) {
            session.firstInput = simpleCloneInputData(input);
          } // to compute scale and rotation we need to store the multiple touches


          if (pointersLength > 1 && !session.firstMultiple) {
            session.firstMultiple = simpleCloneInputData(input);
          } else if (pointersLength === 1) {
            session.firstMultiple = false;
          }

          var firstInput = session.firstInput;
          var firstMultiple = session.firstMultiple;
          var offsetCenter = firstMultiple ? firstMultiple.center : firstInput.center;
          var center = input.center = getCenter(pointers);
          input.timeStamp = now();
          input.deltaTime = input.timeStamp - firstInput.timeStamp;
          input.angle = getAngle(offsetCenter, center);
          input.distance = getDistance(offsetCenter, center);
          computeDeltaXY(session, input);
          input.offsetDirection = getDirection(input.deltaX, input.deltaY);
          var overallVelocity = getVelocity(input.deltaTime, input.deltaX, input.deltaY);
          input.overallVelocityX = overallVelocity.x;
          input.overallVelocityY = overallVelocity.y;
          input.overallVelocity = abs(overallVelocity.x) > abs(overallVelocity.y) ? overallVelocity.x : overallVelocity.y;
          input.scale = firstMultiple ? getScale(firstMultiple.pointers, pointers) : 1;
          input.rotation = firstMultiple ? getRotation(firstMultiple.pointers, pointers) : 0;
          input.maxPointers = !session.prevInput ? input.pointers.length : input.pointers.length > session.prevInput.maxPointers ? input.pointers.length : session.prevInput.maxPointers;
          computeIntervalInputData(session, input); // find the correct target

          var target = manager.element;

          if (hasParent(input.srcEvent.target, target)) {
            target = input.srcEvent.target;
          }

          input.target = target;
        }

        function computeDeltaXY(session, input) {
          var center = input.center;
          var offset = session.offsetDelta || {};
          var prevDelta = session.prevDelta || {};
          var prevInput = session.prevInput || {};

          if (input.eventType === INPUT_START || prevInput.eventType === INPUT_END) {
            prevDelta = session.prevDelta = {
              x: prevInput.deltaX || 0,
              y: prevInput.deltaY || 0
            };
            offset = session.offsetDelta = {
              x: center.x,
              y: center.y
            };
          }

          input.deltaX = prevDelta.x + (center.x - offset.x);
          input.deltaY = prevDelta.y + (center.y - offset.y);
        }
        /**
         * velocity is calculated every x ms
         * @param {Object} session
         * @param {Object} input
         */


        function computeIntervalInputData(session, input) {
          var last = session.lastInterval || input,
              deltaTime = input.timeStamp - last.timeStamp,
              velocity,
              velocityX,
              velocityY,
              direction;

          if (input.eventType != INPUT_CANCEL && (deltaTime > COMPUTE_INTERVAL || last.velocity === undefined$1)) {
            var deltaX = input.deltaX - last.deltaX;
            var deltaY = input.deltaY - last.deltaY;
            var v = getVelocity(deltaTime, deltaX, deltaY);
            velocityX = v.x;
            velocityY = v.y;
            velocity = abs(v.x) > abs(v.y) ? v.x : v.y;
            direction = getDirection(deltaX, deltaY);
            session.lastInterval = input;
          } else {
            // use latest velocity info if it doesn't overtake a minimum period
            velocity = last.velocity;
            velocityX = last.velocityX;
            velocityY = last.velocityY;
            direction = last.direction;
          }

          input.velocity = velocity;
          input.velocityX = velocityX;
          input.velocityY = velocityY;
          input.direction = direction;
        }
        /**
         * create a simple clone from the input used for storage of firstInput and firstMultiple
         * @param {Object} input
         * @returns {Object} clonedInputData
         */


        function simpleCloneInputData(input) {
          // make a simple copy of the pointers because we will get a reference if we don't
          // we only need clientXY for the calculations
          var pointers = [];
          var i = 0;

          while (i < input.pointers.length) {
            pointers[i] = {
              clientX: round(input.pointers[i].clientX),
              clientY: round(input.pointers[i].clientY)
            };
            i++;
          }

          return {
            timeStamp: now(),
            pointers: pointers,
            center: getCenter(pointers),
            deltaX: input.deltaX,
            deltaY: input.deltaY
          };
        }
        /**
         * get the center of all the pointers
         * @param {Array} pointers
         * @return {Object} center contains `x` and `y` properties
         */


        function getCenter(pointers) {
          var pointersLength = pointers.length; // no need to loop when only one touch

          if (pointersLength === 1) {
            return {
              x: round(pointers[0].clientX),
              y: round(pointers[0].clientY)
            };
          }

          var x = 0,
              y = 0,
              i = 0;

          while (i < pointersLength) {
            x += pointers[i].clientX;
            y += pointers[i].clientY;
            i++;
          }

          return {
            x: round(x / pointersLength),
            y: round(y / pointersLength)
          };
        }
        /**
         * calculate the velocity between two points. unit is in px per ms.
         * @param {Number} deltaTime
         * @param {Number} x
         * @param {Number} y
         * @return {Object} velocity `x` and `y`
         */


        function getVelocity(deltaTime, x, y) {
          return {
            x: x / deltaTime || 0,
            y: y / deltaTime || 0
          };
        }
        /**
         * get the direction between two points
         * @param {Number} x
         * @param {Number} y
         * @return {Number} direction
         */


        function getDirection(x, y) {
          if (x === y) {
            return DIRECTION_NONE;
          }

          if (abs(x) >= abs(y)) {
            return x < 0 ? DIRECTION_LEFT : DIRECTION_RIGHT;
          }

          return y < 0 ? DIRECTION_UP : DIRECTION_DOWN;
        }
        /**
         * calculate the absolute distance between two points
         * @param {Object} p1 {x, y}
         * @param {Object} p2 {x, y}
         * @param {Array} [props] containing x and y keys
         * @return {Number} distance
         */


        function getDistance(p1, p2, props) {
          if (!props) {
            props = PROPS_XY;
          }

          var x = p2[props[0]] - p1[props[0]],
              y = p2[props[1]] - p1[props[1]];
          return Math.sqrt(x * x + y * y);
        }
        /**
         * calculate the angle between two coordinates
         * @param {Object} p1
         * @param {Object} p2
         * @param {Array} [props] containing x and y keys
         * @return {Number} angle
         */


        function getAngle(p1, p2, props) {
          if (!props) {
            props = PROPS_XY;
          }

          var x = p2[props[0]] - p1[props[0]],
              y = p2[props[1]] - p1[props[1]];
          return Math.atan2(y, x) * 180 / Math.PI;
        }
        /**
         * calculate the rotation degrees between two pointersets
         * @param {Array} start array of pointers
         * @param {Array} end array of pointers
         * @return {Number} rotation
         */


        function getRotation(start, end) {
          return getAngle(end[1], end[0], PROPS_CLIENT_XY) + getAngle(start[1], start[0], PROPS_CLIENT_XY);
        }
        /**
         * calculate the scale factor between two pointersets
         * no scale is 1, and goes down to 0 when pinched together, and bigger when pinched out
         * @param {Array} start array of pointers
         * @param {Array} end array of pointers
         * @return {Number} scale
         */


        function getScale(start, end) {
          return getDistance(end[0], end[1], PROPS_CLIENT_XY) / getDistance(start[0], start[1], PROPS_CLIENT_XY);
        }

        var MOUSE_INPUT_MAP = {
          mousedown: INPUT_START,
          mousemove: INPUT_MOVE,
          mouseup: INPUT_END
        };
        var MOUSE_ELEMENT_EVENTS = 'mousedown';
        var MOUSE_WINDOW_EVENTS = 'mousemove mouseup';
        /**
         * Mouse events input
         * @constructor
         * @extends Input
         */

        function MouseInput() {
          this.evEl = MOUSE_ELEMENT_EVENTS;
          this.evWin = MOUSE_WINDOW_EVENTS;
          this.pressed = false; // mousedown state

          Input.apply(this, arguments);
        }

        inherit(MouseInput, Input, {
          /**
           * handle mouse events
           * @param {Object} ev
           */
          handler: function MEhandler(ev) {
            var eventType = MOUSE_INPUT_MAP[ev.type]; // on start we want to have the left mouse button down

            if (eventType & INPUT_START && ev.button === 0) {
              this.pressed = true;
            }

            if (eventType & INPUT_MOVE && ev.which !== 1) {
              eventType = INPUT_END;
            } // mouse must be down


            if (!this.pressed) {
              return;
            }

            if (eventType & INPUT_END) {
              this.pressed = false;
            }

            this.callback(this.manager, eventType, {
              pointers: [ev],
              changedPointers: [ev],
              pointerType: INPUT_TYPE_MOUSE,
              srcEvent: ev
            });
          }
        });
        var POINTER_INPUT_MAP = {
          pointerdown: INPUT_START,
          pointermove: INPUT_MOVE,
          pointerup: INPUT_END,
          pointercancel: INPUT_CANCEL,
          pointerout: INPUT_CANCEL
        }; // in IE10 the pointer types is defined as an enum

        var IE10_POINTER_TYPE_ENUM = {
          2: INPUT_TYPE_TOUCH,
          3: INPUT_TYPE_PEN,
          4: INPUT_TYPE_MOUSE,
          5: INPUT_TYPE_KINECT // see https://twitter.com/jacobrossi/status/480596438489890816

        };
        var POINTER_ELEMENT_EVENTS = 'pointerdown';
        var POINTER_WINDOW_EVENTS = 'pointermove pointerup pointercancel'; // IE10 has prefixed support, and case-sensitive

        if (window.MSPointerEvent && !window.PointerEvent) {
          POINTER_ELEMENT_EVENTS = 'MSPointerDown';
          POINTER_WINDOW_EVENTS = 'MSPointerMove MSPointerUp MSPointerCancel';
        }
        /**
         * Pointer events input
         * @constructor
         * @extends Input
         */


        function PointerEventInput() {
          this.evEl = POINTER_ELEMENT_EVENTS;
          this.evWin = POINTER_WINDOW_EVENTS;
          Input.apply(this, arguments);
          this.store = this.manager.session.pointerEvents = [];
        }

        inherit(PointerEventInput, Input, {
          /**
           * handle mouse events
           * @param {Object} ev
           */
          handler: function PEhandler(ev) {
            var store = this.store;
            var removePointer = false;
            var eventTypeNormalized = ev.type.toLowerCase().replace('ms', '');
            var eventType = POINTER_INPUT_MAP[eventTypeNormalized];
            var pointerType = IE10_POINTER_TYPE_ENUM[ev.pointerType] || ev.pointerType;
            var isTouch = pointerType == INPUT_TYPE_TOUCH; // get index of the event in the store

            var storeIndex = inArray(store, ev.pointerId, 'pointerId'); // start and mouse must be down

            if (eventType & INPUT_START && (ev.button === 0 || isTouch)) {
              if (storeIndex < 0) {
                store.push(ev);
                storeIndex = store.length - 1;
              }
            } else if (eventType & (INPUT_END | INPUT_CANCEL)) {
              removePointer = true;
            } // it not found, so the pointer hasn't been down (so it's probably a hover)


            if (storeIndex < 0) {
              return;
            } // update the event in the store


            store[storeIndex] = ev;
            this.callback(this.manager, eventType, {
              pointers: store,
              changedPointers: [ev],
              pointerType: pointerType,
              srcEvent: ev
            });

            if (removePointer) {
              // remove from the store
              store.splice(storeIndex, 1);
            }
          }
        });
        var SINGLE_TOUCH_INPUT_MAP = {
          touchstart: INPUT_START,
          touchmove: INPUT_MOVE,
          touchend: INPUT_END,
          touchcancel: INPUT_CANCEL
        };
        var SINGLE_TOUCH_TARGET_EVENTS = 'touchstart';
        var SINGLE_TOUCH_WINDOW_EVENTS = 'touchstart touchmove touchend touchcancel';
        /**
         * Touch events input
         * @constructor
         * @extends Input
         */

        function SingleTouchInput() {
          this.evTarget = SINGLE_TOUCH_TARGET_EVENTS;
          this.evWin = SINGLE_TOUCH_WINDOW_EVENTS;
          this.started = false;
          Input.apply(this, arguments);
        }

        inherit(SingleTouchInput, Input, {
          handler: function TEhandler(ev) {
            var type = SINGLE_TOUCH_INPUT_MAP[ev.type]; // should we handle the touch events?

            if (type === INPUT_START) {
              this.started = true;
            }

            if (!this.started) {
              return;
            }

            var touches = normalizeSingleTouches.call(this, ev, type); // when done, reset the started state

            if (type & (INPUT_END | INPUT_CANCEL) && touches[0].length - touches[1].length === 0) {
              this.started = false;
            }

            this.callback(this.manager, type, {
              pointers: touches[0],
              changedPointers: touches[1],
              pointerType: INPUT_TYPE_TOUCH,
              srcEvent: ev
            });
          }
        });
        /**
         * @this {TouchInput}
         * @param {Object} ev
         * @param {Number} type flag
         * @returns {undefined|Array} [all, changed]
         */

        function normalizeSingleTouches(ev, type) {
          var all = toArray(ev.touches);
          var changed = toArray(ev.changedTouches);

          if (type & (INPUT_END | INPUT_CANCEL)) {
            all = uniqueArray(all.concat(changed), 'identifier', true);
          }

          return [all, changed];
        }

        var TOUCH_INPUT_MAP = {
          touchstart: INPUT_START,
          touchmove: INPUT_MOVE,
          touchend: INPUT_END,
          touchcancel: INPUT_CANCEL
        };
        var TOUCH_TARGET_EVENTS = 'touchstart touchmove touchend touchcancel';
        /**
         * Multi-user touch events input
         * @constructor
         * @extends Input
         */

        function TouchInput() {
          this.evTarget = TOUCH_TARGET_EVENTS;
          this.targetIds = {};
          Input.apply(this, arguments);
        }

        inherit(TouchInput, Input, {
          handler: function MTEhandler(ev) {
            var type = TOUCH_INPUT_MAP[ev.type];
            var touches = getTouches.call(this, ev, type);

            if (!touches) {
              return;
            }

            this.callback(this.manager, type, {
              pointers: touches[0],
              changedPointers: touches[1],
              pointerType: INPUT_TYPE_TOUCH,
              srcEvent: ev
            });
          }
        });
        /**
         * @this {TouchInput}
         * @param {Object} ev
         * @param {Number} type flag
         * @returns {undefined|Array} [all, changed]
         */

        function getTouches(ev, type) {
          var allTouches = toArray(ev.touches);
          var targetIds = this.targetIds; // when there is only one touch, the process can be simplified

          if (type & (INPUT_START | INPUT_MOVE) && allTouches.length === 1) {
            targetIds[allTouches[0].identifier] = true;
            return [allTouches, allTouches];
          }

          var i,
              targetTouches,
              changedTouches = toArray(ev.changedTouches),
              changedTargetTouches = [],
              target = this.target; // get target touches from touches

          targetTouches = allTouches.filter(function (touch) {
            return hasParent(touch.target, target);
          }); // collect touches

          if (type === INPUT_START) {
            i = 0;

            while (i < targetTouches.length) {
              targetIds[targetTouches[i].identifier] = true;
              i++;
            }
          } // filter changed touches to only contain touches that exist in the collected target ids


          i = 0;

          while (i < changedTouches.length) {
            if (targetIds[changedTouches[i].identifier]) {
              changedTargetTouches.push(changedTouches[i]);
            } // cleanup removed touches


            if (type & (INPUT_END | INPUT_CANCEL)) {
              delete targetIds[changedTouches[i].identifier];
            }

            i++;
          }

          if (!changedTargetTouches.length) {
            return;
          }

          return [// merge targetTouches with changedTargetTouches so it contains ALL touches, including 'end' and 'cancel'
          uniqueArray(targetTouches.concat(changedTargetTouches), 'identifier', true), changedTargetTouches];
        }
        /**
         * Combined touch and mouse input
         *
         * Touch has a higher priority then mouse, and while touching no mouse events are allowed.
         * This because touch devices also emit mouse events while doing a touch.
         *
         * @constructor
         * @extends Input
         */


        var DEDUP_TIMEOUT = 2500;
        var DEDUP_DISTANCE = 25;

        function TouchMouseInput() {
          Input.apply(this, arguments);
          var handler = bindFn(this.handler, this);
          this.touch = new TouchInput(this.manager, handler);
          this.mouse = new MouseInput(this.manager, handler);
          this.primaryTouch = null;
          this.lastTouches = [];
        }

        inherit(TouchMouseInput, Input, {
          /**
           * handle mouse and touch events
           * @param {Hammer} manager
           * @param {String} inputEvent
           * @param {Object} inputData
           */
          handler: function TMEhandler(manager, inputEvent, inputData) {
            var isTouch = inputData.pointerType == INPUT_TYPE_TOUCH,
                isMouse = inputData.pointerType == INPUT_TYPE_MOUSE;

            if (isMouse && inputData.sourceCapabilities && inputData.sourceCapabilities.firesTouchEvents) {
              return;
            } // when we're in a touch event, record touches to  de-dupe synthetic mouse event


            if (isTouch) {
              recordTouches.call(this, inputEvent, inputData);
            } else if (isMouse && isSyntheticEvent.call(this, inputData)) {
              return;
            }

            this.callback(manager, inputEvent, inputData);
          },

          /**
           * remove the event listeners
           */
          destroy: function destroy() {
            this.touch.destroy();
            this.mouse.destroy();
          }
        });

        function recordTouches(eventType, eventData) {
          if (eventType & INPUT_START) {
            this.primaryTouch = eventData.changedPointers[0].identifier;
            setLastTouch.call(this, eventData);
          } else if (eventType & (INPUT_END | INPUT_CANCEL)) {
            setLastTouch.call(this, eventData);
          }
        }

        function setLastTouch(eventData) {
          var touch = eventData.changedPointers[0];

          if (touch.identifier === this.primaryTouch) {
            var lastTouch = {
              x: touch.clientX,
              y: touch.clientY
            };
            this.lastTouches.push(lastTouch);
            var lts = this.lastTouches;

            var removeLastTouch = function removeLastTouch() {
              var i = lts.indexOf(lastTouch);

              if (i > -1) {
                lts.splice(i, 1);
              }
            };

            setTimeout(removeLastTouch, DEDUP_TIMEOUT);
          }
        }

        function isSyntheticEvent(eventData) {
          var x = eventData.srcEvent.clientX,
              y = eventData.srcEvent.clientY;

          for (var i = 0; i < this.lastTouches.length; i++) {
            var t = this.lastTouches[i];
            var dx = Math.abs(x - t.x),
                dy = Math.abs(y - t.y);

            if (dx <= DEDUP_DISTANCE && dy <= DEDUP_DISTANCE) {
              return true;
            }
          }

          return false;
        }

        var PREFIXED_TOUCH_ACTION = prefixed(TEST_ELEMENT.style, 'touchAction');
        var NATIVE_TOUCH_ACTION = PREFIXED_TOUCH_ACTION !== undefined$1; // magical touchAction value

        var TOUCH_ACTION_COMPUTE = 'compute';
        var TOUCH_ACTION_AUTO = 'auto';
        var TOUCH_ACTION_MANIPULATION = 'manipulation'; // not implemented

        var TOUCH_ACTION_NONE = 'none';
        var TOUCH_ACTION_PAN_X = 'pan-x';
        var TOUCH_ACTION_PAN_Y = 'pan-y';
        var TOUCH_ACTION_MAP = getTouchActionProps();
        /**
         * Touch Action
         * sets the touchAction property or uses the js alternative
         * @param {Manager} manager
         * @param {String} value
         * @constructor
         */

        function TouchAction(manager, value) {
          this.manager = manager;
          this.set(value);
        }

        TouchAction.prototype = {
          /**
           * set the touchAction value on the element or enable the polyfill
           * @param {String} value
           */
          set: function set(value) {
            // find out the touch-action by the event handlers
            if (value == TOUCH_ACTION_COMPUTE) {
              value = this.compute();
            }

            if (NATIVE_TOUCH_ACTION && this.manager.element.style && TOUCH_ACTION_MAP[value]) {
              this.manager.element.style[PREFIXED_TOUCH_ACTION] = value;
            }

            this.actions = value.toLowerCase().trim();
          },

          /**
           * just re-set the touchAction value
           */
          update: function update() {
            this.set(this.manager.options.touchAction);
          },

          /**
           * compute the value for the touchAction property based on the recognizer's settings
           * @returns {String} value
           */
          compute: function compute() {
            var actions = [];
            each(this.manager.recognizers, function (recognizer) {
              if (boolOrFn(recognizer.options.enable, [recognizer])) {
                actions = actions.concat(recognizer.getTouchAction());
              }
            });
            return cleanTouchActions(actions.join(' '));
          },

          /**
           * this method is called on each input cycle and provides the preventing of the browser behavior
           * @param {Object} input
           */
          preventDefaults: function preventDefaults(input) {
            var srcEvent = input.srcEvent;
            var direction = input.offsetDirection; // if the touch action did prevented once this session

            if (this.manager.session.prevented) {
              srcEvent.preventDefault();
              return;
            }

            var actions = this.actions;
            var hasNone = inStr(actions, TOUCH_ACTION_NONE) && !TOUCH_ACTION_MAP[TOUCH_ACTION_NONE];
            var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y) && !TOUCH_ACTION_MAP[TOUCH_ACTION_PAN_Y];
            var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X) && !TOUCH_ACTION_MAP[TOUCH_ACTION_PAN_X];

            if (hasNone) {
              //do not prevent defaults if this is a tap gesture
              var isTapPointer = input.pointers.length === 1;
              var isTapMovement = input.distance < 2;
              var isTapTouchTime = input.deltaTime < 250;

              if (isTapPointer && isTapMovement && isTapTouchTime) {
                return;
              }
            }

            if (hasPanX && hasPanY) {
              // `pan-x pan-y` means browser handles all scrolling/panning, do not prevent
              return;
            }

            if (hasNone || hasPanY && direction & DIRECTION_HORIZONTAL || hasPanX && direction & DIRECTION_VERTICAL) {
              return this.preventSrc(srcEvent);
            }
          },

          /**
           * call preventDefault to prevent the browser's default behavior (scrolling in most cases)
           * @param {Object} srcEvent
           */
          preventSrc: function preventSrc(srcEvent) {
            this.manager.session.prevented = true;
            srcEvent.preventDefault();
          }
        };
        /**
         * when the touchActions are collected they are not a valid value, so we need to clean things up. *
         * @param {String} actions
         * @returns {*}
         */

        function cleanTouchActions(actions) {
          // none
          if (inStr(actions, TOUCH_ACTION_NONE)) {
            return TOUCH_ACTION_NONE;
          }

          var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X);
          var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y); // if both pan-x and pan-y are set (different recognizers
          // for different directions, e.g. horizontal pan but vertical swipe?)
          // we need none (as otherwise with pan-x pan-y combined none of these
          // recognizers will work, since the browser would handle all panning

          if (hasPanX && hasPanY) {
            return TOUCH_ACTION_NONE;
          } // pan-x OR pan-y


          if (hasPanX || hasPanY) {
            return hasPanX ? TOUCH_ACTION_PAN_X : TOUCH_ACTION_PAN_Y;
          } // manipulation


          if (inStr(actions, TOUCH_ACTION_MANIPULATION)) {
            return TOUCH_ACTION_MANIPULATION;
          }

          return TOUCH_ACTION_AUTO;
        }

        function getTouchActionProps() {
          if (!NATIVE_TOUCH_ACTION) {
            return false;
          }

          var touchMap = {};
          var cssSupports = window.CSS && window.CSS.supports;
          ['auto', 'manipulation', 'pan-y', 'pan-x', 'pan-x pan-y', 'none'].forEach(function (val) {
            // If css.supports is not supported but there is native touch-action assume it supports
            // all values. This is the case for IE 10 and 11.
            touchMap[val] = cssSupports ? window.CSS.supports('touch-action', val) : true;
          });
          return touchMap;
        }
        /**
         * Recognizer flow explained; *
         * All recognizers have the initial state of POSSIBLE when a input session starts.
         * The definition of a input session is from the first input until the last input, with all it's movement in it. *
         * Example session for mouse-input: mousedown -> mousemove -> mouseup
         *
         * On each recognizing cycle (see Manager.recognize) the .recognize() method is executed
         * which determines with state it should be.
         *
         * If the recognizer has the state FAILED, CANCELLED or RECOGNIZED (equals ENDED), it is reset to
         * POSSIBLE to give it another change on the next cycle.
         *
         *               Possible
         *                  |
         *            +-----+---------------+
         *            |                     |
         *      +-----+-----+               |
         *      |           |               |
         *   Failed      Cancelled          |
         *                          +-------+------+
         *                          |              |
         *                      Recognized       Began
         *                                         |
         *                                      Changed
         *                                         |
         *                                  Ended/Recognized
         */


        var STATE_POSSIBLE = 1;
        var STATE_BEGAN = 2;
        var STATE_CHANGED = 4;
        var STATE_ENDED = 8;
        var STATE_RECOGNIZED = STATE_ENDED;
        var STATE_CANCELLED = 16;
        var STATE_FAILED = 32;
        /**
         * Recognizer
         * Every recognizer needs to extend from this class.
         * @constructor
         * @param {Object} options
         */

        function Recognizer(options) {
          this.options = assign({}, this.defaults, options || {});
          this.id = uniqueId();
          this.manager = null; // default is enable true

          this.options.enable = ifUndefined(this.options.enable, true);
          this.state = STATE_POSSIBLE;
          this.simultaneous = {};
          this.requireFail = [];
        }

        Recognizer.prototype = {
          /**
           * @virtual
           * @type {Object}
           */
          defaults: {},

          /**
           * set options
           * @param {Object} options
           * @return {Recognizer}
           */
          set: function set(options) {
            assign(this.options, options); // also update the touchAction, in case something changed about the directions/enabled state

            this.manager && this.manager.touchAction.update();
            return this;
          },

          /**
           * recognize simultaneous with an other recognizer.
           * @param {Recognizer} otherRecognizer
           * @returns {Recognizer} this
           */
          recognizeWith: function recognizeWith(otherRecognizer) {
            if (invokeArrayArg(otherRecognizer, 'recognizeWith', this)) {
              return this;
            }

            var simultaneous = this.simultaneous;
            otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);

            if (!simultaneous[otherRecognizer.id]) {
              simultaneous[otherRecognizer.id] = otherRecognizer;
              otherRecognizer.recognizeWith(this);
            }

            return this;
          },

          /**
           * drop the simultaneous link. it doesnt remove the link on the other recognizer.
           * @param {Recognizer} otherRecognizer
           * @returns {Recognizer} this
           */
          dropRecognizeWith: function dropRecognizeWith(otherRecognizer) {
            if (invokeArrayArg(otherRecognizer, 'dropRecognizeWith', this)) {
              return this;
            }

            otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
            delete this.simultaneous[otherRecognizer.id];
            return this;
          },

          /**
           * recognizer can only run when an other is failing
           * @param {Recognizer} otherRecognizer
           * @returns {Recognizer} this
           */
          requireFailure: function requireFailure(otherRecognizer) {
            if (invokeArrayArg(otherRecognizer, 'requireFailure', this)) {
              return this;
            }

            var requireFail = this.requireFail;
            otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);

            if (inArray(requireFail, otherRecognizer) === -1) {
              requireFail.push(otherRecognizer);
              otherRecognizer.requireFailure(this);
            }

            return this;
          },

          /**
           * drop the requireFailure link. it does not remove the link on the other recognizer.
           * @param {Recognizer} otherRecognizer
           * @returns {Recognizer} this
           */
          dropRequireFailure: function dropRequireFailure(otherRecognizer) {
            if (invokeArrayArg(otherRecognizer, 'dropRequireFailure', this)) {
              return this;
            }

            otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
            var index = inArray(this.requireFail, otherRecognizer);

            if (index > -1) {
              this.requireFail.splice(index, 1);
            }

            return this;
          },

          /**
           * has require failures boolean
           * @returns {boolean}
           */
          hasRequireFailures: function hasRequireFailures() {
            return this.requireFail.length > 0;
          },

          /**
           * if the recognizer can recognize simultaneous with an other recognizer
           * @param {Recognizer} otherRecognizer
           * @returns {Boolean}
           */
          canRecognizeWith: function canRecognizeWith(otherRecognizer) {
            return !!this.simultaneous[otherRecognizer.id];
          },

          /**
           * You should use `tryEmit` instead of `emit` directly to check
           * that all the needed recognizers has failed before emitting.
           * @param {Object} input
           */
          emit: function emit(input) {
            var self = this;
            var state = this.state;

            function emit(event) {
              self.manager.emit(event, input);
            } // 'panstart' and 'panmove'


            if (state < STATE_ENDED) {
              emit(self.options.event + stateStr(state));
            }

            emit(self.options.event); // simple 'eventName' events

            if (input.additionalEvent) {
              // additional event(panleft, panright, pinchin, pinchout...)
              emit(input.additionalEvent);
            } // panend and pancancel


            if (state >= STATE_ENDED) {
              emit(self.options.event + stateStr(state));
            }
          },

          /**
           * Check that all the require failure recognizers has failed,
           * if true, it emits a gesture event,
           * otherwise, setup the state to FAILED.
           * @param {Object} input
           */
          tryEmit: function tryEmit(input) {
            if (this.canEmit()) {
              return this.emit(input);
            } // it's failing anyway


            this.state = STATE_FAILED;
          },

          /**
           * can we emit?
           * @returns {boolean}
           */
          canEmit: function canEmit() {
            var i = 0;

            while (i < this.requireFail.length) {
              if (!(this.requireFail[i].state & (STATE_FAILED | STATE_POSSIBLE))) {
                return false;
              }

              i++;
            }

            return true;
          },

          /**
           * update the recognizer
           * @param {Object} inputData
           */
          recognize: function recognize(inputData) {
            // make a new copy of the inputData
            // so we can change the inputData without messing up the other recognizers
            var inputDataClone = assign({}, inputData); // is is enabled and allow recognizing?

            if (!boolOrFn(this.options.enable, [this, inputDataClone])) {
              this.reset();
              this.state = STATE_FAILED;
              return;
            } // reset when we've reached the end


            if (this.state & (STATE_RECOGNIZED | STATE_CANCELLED | STATE_FAILED)) {
              this.state = STATE_POSSIBLE;
            }

            this.state = this.process(inputDataClone); // the recognizer has recognized a gesture
            // so trigger an event

            if (this.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED | STATE_CANCELLED)) {
              this.tryEmit(inputDataClone);
            }
          },

          /**
           * return the state of the recognizer
           * the actual recognizing happens in this method
           * @virtual
           * @param {Object} inputData
           * @returns {Const} STATE
           */
          process: function process(inputData) {},
          // jshint ignore:line

          /**
           * return the preferred touch-action
           * @virtual
           * @returns {Array}
           */
          getTouchAction: function getTouchAction() {},

          /**
           * called when the gesture isn't allowed to recognize
           * like when another is being recognized or it is disabled
           * @virtual
           */
          reset: function reset() {}
        };
        /**
         * get a usable string, used as event postfix
         * @param {Const} state
         * @returns {String} state
         */

        function stateStr(state) {
          if (state & STATE_CANCELLED) {
            return 'cancel';
          } else if (state & STATE_ENDED) {
            return 'end';
          } else if (state & STATE_CHANGED) {
            return 'move';
          } else if (state & STATE_BEGAN) {
            return 'start';
          }

          return '';
        }
        /**
         * direction cons to string
         * @param {Const} direction
         * @returns {String}
         */


        function directionStr(direction) {
          if (direction == DIRECTION_DOWN) {
            return 'down';
          } else if (direction == DIRECTION_UP) {
            return 'up';
          } else if (direction == DIRECTION_LEFT) {
            return 'left';
          } else if (direction == DIRECTION_RIGHT) {
            return 'right';
          }

          return '';
        }
        /**
         * get a recognizer by name if it is bound to a manager
         * @param {Recognizer|String} otherRecognizer
         * @param {Recognizer} recognizer
         * @returns {Recognizer}
         */


        function getRecognizerByNameIfManager(otherRecognizer, recognizer) {
          var manager = recognizer.manager;

          if (manager) {
            return manager.get(otherRecognizer);
          }

          return otherRecognizer;
        }
        /**
         * This recognizer is just used as a base for the simple attribute recognizers.
         * @constructor
         * @extends Recognizer
         */


        function AttrRecognizer() {
          Recognizer.apply(this, arguments);
        }

        inherit(AttrRecognizer, Recognizer, {
          /**
           * @namespace
           * @memberof AttrRecognizer
           */
          defaults: {
            /**
             * @type {Number}
             * @default 1
             */
            pointers: 1
          },

          /**
           * Used to check if it the recognizer receives valid input, like input.distance > 10.
           * @memberof AttrRecognizer
           * @param {Object} input
           * @returns {Boolean} recognized
           */
          attrTest: function attrTest(input) {
            var optionPointers = this.options.pointers;
            return optionPointers === 0 || input.pointers.length === optionPointers;
          },

          /**
           * Process the input and return the state for the recognizer
           * @memberof AttrRecognizer
           * @param {Object} input
           * @returns {*} State
           */
          process: function process(input) {
            var state = this.state;
            var eventType = input.eventType;
            var isRecognized = state & (STATE_BEGAN | STATE_CHANGED);
            var isValid = this.attrTest(input); // on cancel input and we've recognized before, return STATE_CANCELLED

            if (isRecognized && (eventType & INPUT_CANCEL || !isValid)) {
              return state | STATE_CANCELLED;
            } else if (isRecognized || isValid) {
              if (eventType & INPUT_END) {
                return state | STATE_ENDED;
              } else if (!(state & STATE_BEGAN)) {
                return STATE_BEGAN;
              }

              return state | STATE_CHANGED;
            }

            return STATE_FAILED;
          }
        });
        /**
         * Pan
         * Recognized when the pointer is down and moved in the allowed direction.
         * @constructor
         * @extends AttrRecognizer
         */

        function PanRecognizer() {
          AttrRecognizer.apply(this, arguments);
          this.pX = null;
          this.pY = null;
        }

        inherit(PanRecognizer, AttrRecognizer, {
          /**
           * @namespace
           * @memberof PanRecognizer
           */
          defaults: {
            event: 'pan',
            threshold: 10,
            pointers: 1,
            direction: DIRECTION_ALL
          },
          getTouchAction: function getTouchAction() {
            var direction = this.options.direction;
            var actions = [];

            if (direction & DIRECTION_HORIZONTAL) {
              actions.push(TOUCH_ACTION_PAN_Y);
            }

            if (direction & DIRECTION_VERTICAL) {
              actions.push(TOUCH_ACTION_PAN_X);
            }

            return actions;
          },
          directionTest: function directionTest(input) {
            var options = this.options;
            var hasMoved = true;
            var distance = input.distance;
            var direction = input.direction;
            var x = input.deltaX;
            var y = input.deltaY; // lock to axis?

            if (!(direction & options.direction)) {
              if (options.direction & DIRECTION_HORIZONTAL) {
                direction = x === 0 ? DIRECTION_NONE : x < 0 ? DIRECTION_LEFT : DIRECTION_RIGHT;
                hasMoved = x != this.pX;
                distance = Math.abs(input.deltaX);
              } else {
                direction = y === 0 ? DIRECTION_NONE : y < 0 ? DIRECTION_UP : DIRECTION_DOWN;
                hasMoved = y != this.pY;
                distance = Math.abs(input.deltaY);
              }
            }

            input.direction = direction;
            return hasMoved && distance > options.threshold && direction & options.direction;
          },
          attrTest: function attrTest(input) {
            return AttrRecognizer.prototype.attrTest.call(this, input) && (this.state & STATE_BEGAN || !(this.state & STATE_BEGAN) && this.directionTest(input));
          },
          emit: function emit(input) {
            this.pX = input.deltaX;
            this.pY = input.deltaY;
            var direction = directionStr(input.direction);

            if (direction) {
              input.additionalEvent = this.options.event + direction;
            }

            this._super.emit.call(this, input);
          }
        });
        /**
         * Pinch
         * Recognized when two or more pointers are moving toward (zoom-in) or away from each other (zoom-out).
         * @constructor
         * @extends AttrRecognizer
         */

        function PinchRecognizer() {
          AttrRecognizer.apply(this, arguments);
        }

        inherit(PinchRecognizer, AttrRecognizer, {
          /**
           * @namespace
           * @memberof PinchRecognizer
           */
          defaults: {
            event: 'pinch',
            threshold: 0,
            pointers: 2
          },
          getTouchAction: function getTouchAction() {
            return [TOUCH_ACTION_NONE];
          },
          attrTest: function attrTest(input) {
            return this._super.attrTest.call(this, input) && (Math.abs(input.scale - 1) > this.options.threshold || this.state & STATE_BEGAN);
          },
          emit: function emit(input) {
            if (input.scale !== 1) {
              var inOut = input.scale < 1 ? 'in' : 'out';
              input.additionalEvent = this.options.event + inOut;
            }

            this._super.emit.call(this, input);
          }
        });
        /**
         * Press
         * Recognized when the pointer is down for x ms without any movement.
         * @constructor
         * @extends Recognizer
         */

        function PressRecognizer() {
          Recognizer.apply(this, arguments);
          this._timer = null;
          this._input = null;
        }

        inherit(PressRecognizer, Recognizer, {
          /**
           * @namespace
           * @memberof PressRecognizer
           */
          defaults: {
            event: 'press',
            pointers: 1,
            time: 251,
            // minimal time of the pointer to be pressed
            threshold: 9 // a minimal movement is ok, but keep it low

          },
          getTouchAction: function getTouchAction() {
            return [TOUCH_ACTION_AUTO];
          },
          process: function process(input) {
            var options = this.options;
            var validPointers = input.pointers.length === options.pointers;
            var validMovement = input.distance < options.threshold;
            var validTime = input.deltaTime > options.time;
            this._input = input; // we only allow little movement
            // and we've reached an end event, so a tap is possible

            if (!validMovement || !validPointers || input.eventType & (INPUT_END | INPUT_CANCEL) && !validTime) {
              this.reset();
            } else if (input.eventType & INPUT_START) {
              this.reset();
              this._timer = setTimeoutContext(function () {
                this.state = STATE_RECOGNIZED;
                this.tryEmit();
              }, options.time, this);
            } else if (input.eventType & INPUT_END) {
              return STATE_RECOGNIZED;
            }

            return STATE_FAILED;
          },
          reset: function reset() {
            clearTimeout(this._timer);
          },
          emit: function emit(input) {
            if (this.state !== STATE_RECOGNIZED) {
              return;
            }

            if (input && input.eventType & INPUT_END) {
              this.manager.emit(this.options.event + 'up', input);
            } else {
              this._input.timeStamp = now();
              this.manager.emit(this.options.event, this._input);
            }
          }
        });
        /**
         * Rotate
         * Recognized when two or more pointer are moving in a circular motion.
         * @constructor
         * @extends AttrRecognizer
         */

        function RotateRecognizer() {
          AttrRecognizer.apply(this, arguments);
        }

        inherit(RotateRecognizer, AttrRecognizer, {
          /**
           * @namespace
           * @memberof RotateRecognizer
           */
          defaults: {
            event: 'rotate',
            threshold: 0,
            pointers: 2
          },
          getTouchAction: function getTouchAction() {
            return [TOUCH_ACTION_NONE];
          },
          attrTest: function attrTest(input) {
            return this._super.attrTest.call(this, input) && (Math.abs(input.rotation) > this.options.threshold || this.state & STATE_BEGAN);
          }
        });
        /**
         * Swipe
         * Recognized when the pointer is moving fast (velocity), with enough distance in the allowed direction.
         * @constructor
         * @extends AttrRecognizer
         */

        function SwipeRecognizer() {
          AttrRecognizer.apply(this, arguments);
        }

        inherit(SwipeRecognizer, AttrRecognizer, {
          /**
           * @namespace
           * @memberof SwipeRecognizer
           */
          defaults: {
            event: 'swipe',
            threshold: 10,
            velocity: 0.3,
            direction: DIRECTION_HORIZONTAL | DIRECTION_VERTICAL,
            pointers: 1
          },
          getTouchAction: function getTouchAction() {
            return PanRecognizer.prototype.getTouchAction.call(this);
          },
          attrTest: function attrTest(input) {
            var direction = this.options.direction;
            var velocity;

            if (direction & (DIRECTION_HORIZONTAL | DIRECTION_VERTICAL)) {
              velocity = input.overallVelocity;
            } else if (direction & DIRECTION_HORIZONTAL) {
              velocity = input.overallVelocityX;
            } else if (direction & DIRECTION_VERTICAL) {
              velocity = input.overallVelocityY;
            }

            return this._super.attrTest.call(this, input) && direction & input.offsetDirection && input.distance > this.options.threshold && input.maxPointers == this.options.pointers && abs(velocity) > this.options.velocity && input.eventType & INPUT_END;
          },
          emit: function emit(input) {
            var direction = directionStr(input.offsetDirection);

            if (direction) {
              this.manager.emit(this.options.event + direction, input);
            }

            this.manager.emit(this.options.event, input);
          }
        });
        /**
         * A tap is ecognized when the pointer is doing a small tap/click. Multiple taps are recognized if they occur
         * between the given interval and position. The delay option can be used to recognize multi-taps without firing
         * a single tap.
         *
         * The eventData from the emitted event contains the property `tapCount`, which contains the amount of
         * multi-taps being recognized.
         * @constructor
         * @extends Recognizer
         */

        function TapRecognizer() {
          Recognizer.apply(this, arguments); // previous time and center,
          // used for tap counting

          this.pTime = false;
          this.pCenter = false;
          this._timer = null;
          this._input = null;
          this.count = 0;
        }

        inherit(TapRecognizer, Recognizer, {
          /**
           * @namespace
           * @memberof PinchRecognizer
           */
          defaults: {
            event: 'tap',
            pointers: 1,
            taps: 1,
            interval: 300,
            // max time between the multi-tap taps
            time: 250,
            // max time of the pointer to be down (like finger on the screen)
            threshold: 9,
            // a minimal movement is ok, but keep it low
            posThreshold: 10 // a multi-tap can be a bit off the initial position

          },
          getTouchAction: function getTouchAction() {
            return [TOUCH_ACTION_MANIPULATION];
          },
          process: function process(input) {
            var options = this.options;
            var validPointers = input.pointers.length === options.pointers;
            var validMovement = input.distance < options.threshold;
            var validTouchTime = input.deltaTime < options.time;
            this.reset();

            if (input.eventType & INPUT_START && this.count === 0) {
              return this.failTimeout();
            } // we only allow little movement
            // and we've reached an end event, so a tap is possible


            if (validMovement && validTouchTime && validPointers) {
              if (input.eventType != INPUT_END) {
                return this.failTimeout();
              }

              var validInterval = this.pTime ? input.timeStamp - this.pTime < options.interval : true;
              var validMultiTap = !this.pCenter || getDistance(this.pCenter, input.center) < options.posThreshold;
              this.pTime = input.timeStamp;
              this.pCenter = input.center;

              if (!validMultiTap || !validInterval) {
                this.count = 1;
              } else {
                this.count += 1;
              }

              this._input = input; // if tap count matches we have recognized it,
              // else it has began recognizing...

              var tapCount = this.count % options.taps;

              if (tapCount === 0) {
                // no failing requirements, immediately trigger the tap event
                // or wait as long as the multitap interval to trigger
                if (!this.hasRequireFailures()) {
                  return STATE_RECOGNIZED;
                } else {
                  this._timer = setTimeoutContext(function () {
                    this.state = STATE_RECOGNIZED;
                    this.tryEmit();
                  }, options.interval, this);
                  return STATE_BEGAN;
                }
              }
            }

            return STATE_FAILED;
          },
          failTimeout: function failTimeout() {
            this._timer = setTimeoutContext(function () {
              this.state = STATE_FAILED;
            }, this.options.interval, this);
            return STATE_FAILED;
          },
          reset: function reset() {
            clearTimeout(this._timer);
          },
          emit: function emit() {
            if (this.state == STATE_RECOGNIZED) {
              this._input.tapCount = this.count;
              this.manager.emit(this.options.event, this._input);
            }
          }
        });
        /**
         * Simple way to create a manager with a default set of recognizers.
         * @param {HTMLElement} element
         * @param {Object} [options]
         * @constructor
         */

        function Hammer(element, options) {
          options = options || {};
          options.recognizers = ifUndefined(options.recognizers, Hammer.defaults.preset);
          return new Manager(element, options);
        }
        /**
         * @const {string}
         */


        Hammer.VERSION = '2.0.7';
        /**
         * default settings
         * @namespace
         */

        Hammer.defaults = {
          /**
           * set if DOM events are being triggered.
           * But this is slower and unused by simple implementations, so disabled by default.
           * @type {Boolean}
           * @default false
           */
          domEvents: false,

          /**
           * The value for the touchAction property/fallback.
           * When set to `compute` it will magically set the correct value based on the added recognizers.
           * @type {String}
           * @default compute
           */
          touchAction: TOUCH_ACTION_COMPUTE,

          /**
           * @type {Boolean}
           * @default true
           */
          enable: true,

          /**
           * EXPERIMENTAL FEATURE -- can be removed/changed
           * Change the parent input target element.
           * If Null, then it is being set the to main element.
           * @type {Null|EventTarget}
           * @default null
           */
          inputTarget: null,

          /**
           * force an input class
           * @type {Null|Function}
           * @default null
           */
          inputClass: null,

          /**
           * Default recognizer setup when calling `Hammer()`
           * When creating a new Manager these will be skipped.
           * @type {Array}
           */
          preset: [// RecognizerClass, options, [recognizeWith, ...], [requireFailure, ...]
          [RotateRecognizer, {
            enable: false
          }], [PinchRecognizer, {
            enable: false
          }, ['rotate']], [SwipeRecognizer, {
            direction: DIRECTION_HORIZONTAL
          }], [PanRecognizer, {
            direction: DIRECTION_HORIZONTAL
          }, ['swipe']], [TapRecognizer], [TapRecognizer, {
            event: 'doubletap',
            taps: 2
          }, ['tap']], [PressRecognizer]],

          /**
           * Some CSS properties can be used to improve the working of Hammer.
           * Add them to this method and they will be set when creating a new Manager.
           * @namespace
           */
          cssProps: {
            /**
             * Disables text selection to improve the dragging gesture. Mainly for desktop browsers.
             * @type {String}
             * @default 'none'
             */
            userSelect: 'none',

            /**
             * Disable the Windows Phone grippers when pressing an element.
             * @type {String}
             * @default 'none'
             */
            touchSelect: 'none',

            /**
             * Disables the default callout shown when you touch and hold a touch target.
             * On iOS, when you touch and hold a touch target such as a link, Safari displays
             * a callout containing information about the link. This property allows you to disable that callout.
             * @type {String}
             * @default 'none'
             */
            touchCallout: 'none',

            /**
             * Specifies whether zooming is enabled. Used by IE10>
             * @type {String}
             * @default 'none'
             */
            contentZooming: 'none',

            /**
             * Specifies that an entire element should be draggable instead of its contents. Mainly for desktop browsers.
             * @type {String}
             * @default 'none'
             */
            userDrag: 'none',

            /**
             * Overrides the highlight color shown when the user taps a link or a JavaScript
             * clickable element in iOS. This property obeys the alpha value, if specified.
             * @type {String}
             * @default 'rgba(0,0,0,0)'
             */
            tapHighlightColor: 'rgba(0,0,0,0)'
          }
        };
        var STOP = 1;
        var FORCED_STOP = 2;
        /**
         * Manager
         * @param {HTMLElement} element
         * @param {Object} [options]
         * @constructor
         */

        function Manager(element, options) {
          this.options = assign({}, Hammer.defaults, options || {});
          this.options.inputTarget = this.options.inputTarget || element;
          this.handlers = {};
          this.session = {};
          this.recognizers = [];
          this.oldCssProps = {};
          this.element = element;
          this.input = createInputInstance(this);
          this.touchAction = new TouchAction(this, this.options.touchAction);
          toggleCssProps(this, true);
          each(this.options.recognizers, function (item) {
            var recognizer = this.add(new item[0](item[1]));
            item[2] && recognizer.recognizeWith(item[2]);
            item[3] && recognizer.requireFailure(item[3]);
          }, this);
        }

        Manager.prototype = {
          /**
           * set options
           * @param {Object} options
           * @returns {Manager}
           */
          set: function set(options) {
            assign(this.options, options); // Options that need a little more setup

            if (options.touchAction) {
              this.touchAction.update();
            }

            if (options.inputTarget) {
              // Clean up existing event listeners and reinitialize
              this.input.destroy();
              this.input.target = options.inputTarget;
              this.input.init();
            }

            return this;
          },

          /**
           * stop recognizing for this session.
           * This session will be discarded, when a new [input]start event is fired.
           * When forced, the recognizer cycle is stopped immediately.
           * @param {Boolean} [force]
           */
          stop: function stop(force) {
            this.session.stopped = force ? FORCED_STOP : STOP;
          },

          /**
           * run the recognizers!
           * called by the inputHandler function on every movement of the pointers (touches)
           * it walks through all the recognizers and tries to detect the gesture that is being made
           * @param {Object} inputData
           */
          recognize: function recognize(inputData) {
            var session = this.session;

            if (session.stopped) {
              return;
            } // run the touch-action polyfill


            this.touchAction.preventDefaults(inputData);
            var recognizer;
            var recognizers = this.recognizers; // this holds the recognizer that is being recognized.
            // so the recognizer's state needs to be BEGAN, CHANGED, ENDED or RECOGNIZED
            // if no recognizer is detecting a thing, it is set to `null`

            var curRecognizer = session.curRecognizer; // reset when the last recognizer is recognized
            // or when we're in a new session

            if (!curRecognizer || curRecognizer && curRecognizer.state & STATE_RECOGNIZED) {
              curRecognizer = session.curRecognizer = null;
            }

            var i = 0;

            while (i < recognizers.length) {
              recognizer = recognizers[i]; // find out if we are allowed try to recognize the input for this one.
              // 1.   allow if the session is NOT forced stopped (see the .stop() method)
              // 2.   allow if we still haven't recognized a gesture in this session, or the this recognizer is the one
              //      that is being recognized.
              // 3.   allow if the recognizer is allowed to run simultaneous with the current recognized recognizer.
              //      this can be setup with the `recognizeWith()` method on the recognizer.

              if (session.stopped !== FORCED_STOP && ( // 1
              !curRecognizer || recognizer == curRecognizer || // 2
              recognizer.canRecognizeWith(curRecognizer))) {
                // 3
                recognizer.recognize(inputData);
              } else {
                recognizer.reset();
              } // if the recognizer has been recognizing the input as a valid gesture, we want to store this one as the
              // current active recognizer. but only if we don't already have an active recognizer


              if (!curRecognizer && recognizer.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED)) {
                curRecognizer = session.curRecognizer = recognizer;
              }

              i++;
            }
          },

          /**
           * get a recognizer by its event name.
           * @param {Recognizer|String} recognizer
           * @returns {Recognizer|Null}
           */
          get: function get(recognizer) {
            if (recognizer instanceof Recognizer) {
              return recognizer;
            }

            var recognizers = this.recognizers;

            for (var i = 0; i < recognizers.length; i++) {
              if (recognizers[i].options.event == recognizer) {
                return recognizers[i];
              }
            }

            return null;
          },

          /**
           * add a recognizer to the manager
           * existing recognizers with the same event name will be removed
           * @param {Recognizer} recognizer
           * @returns {Recognizer|Manager}
           */
          add: function add(recognizer) {
            if (invokeArrayArg(recognizer, 'add', this)) {
              return this;
            } // remove existing


            var existing = this.get(recognizer.options.event);

            if (existing) {
              this.remove(existing);
            }

            this.recognizers.push(recognizer);
            recognizer.manager = this;
            this.touchAction.update();
            return recognizer;
          },

          /**
           * remove a recognizer by name or instance
           * @param {Recognizer|String} recognizer
           * @returns {Manager}
           */
          remove: function remove(recognizer) {
            if (invokeArrayArg(recognizer, 'remove', this)) {
              return this;
            }

            recognizer = this.get(recognizer); // let's make sure this recognizer exists

            if (recognizer) {
              var recognizers = this.recognizers;
              var index = inArray(recognizers, recognizer);

              if (index !== -1) {
                recognizers.splice(index, 1);
                this.touchAction.update();
              }
            }

            return this;
          },

          /**
           * bind event
           * @param {String} events
           * @param {Function} handler
           * @returns {EventEmitter} this
           */
          on: function on(events, handler) {
            if (events === undefined$1) {
              return;
            }

            if (handler === undefined$1) {
              return;
            }

            var handlers = this.handlers;
            each(splitStr(events), function (event) {
              handlers[event] = handlers[event] || [];
              handlers[event].push(handler);
            });
            return this;
          },

          /**
           * unbind event, leave emit blank to remove all handlers
           * @param {String} events
           * @param {Function} [handler]
           * @returns {EventEmitter} this
           */
          off: function off(events, handler) {
            if (events === undefined$1) {
              return;
            }

            var handlers = this.handlers;
            each(splitStr(events), function (event) {
              if (!handler) {
                delete handlers[event];
              } else {
                handlers[event] && handlers[event].splice(inArray(handlers[event], handler), 1);
              }
            });
            return this;
          },

          /**
           * emit event to the listeners
           * @param {String} event
           * @param {Object} data
           */
          emit: function emit(event, data) {
            // we also want to trigger dom events
            if (this.options.domEvents) {
              triggerDomEvent(event, data);
            } // no handlers, so skip it all


            var handlers = this.handlers[event] && this.handlers[event].slice();

            if (!handlers || !handlers.length) {
              return;
            }

            data.type = event;

            data.preventDefault = function () {
              data.srcEvent.preventDefault();
            };

            var i = 0;

            while (i < handlers.length) {
              handlers[i](data);
              i++;
            }
          },

          /**
           * destroy the manager and unbinds all events
           * it doesn't unbind dom events, that is the user own responsibility
           */
          destroy: function destroy() {
            this.element && toggleCssProps(this, false);
            this.handlers = {};
            this.session = {};
            this.input.destroy();
            this.element = null;
          }
        };
        /**
         * add/remove the css properties as defined in manager.options.cssProps
         * @param {Manager} manager
         * @param {Boolean} add
         */

        function toggleCssProps(manager, add) {
          var element = manager.element;

          if (!element.style) {
            return;
          }

          var prop;
          each(manager.options.cssProps, function (value, name) {
            prop = prefixed(element.style, name);

            if (add) {
              manager.oldCssProps[prop] = element.style[prop];
              element.style[prop] = value;
            } else {
              element.style[prop] = manager.oldCssProps[prop] || '';
            }
          });

          if (!add) {
            manager.oldCssProps = {};
          }
        }
        /**
         * trigger dom event
         * @param {String} event
         * @param {Object} data
         */


        function triggerDomEvent(event, data) {
          var gestureEvent = document.createEvent('Event');
          gestureEvent.initEvent(event, true, true);
          gestureEvent.gesture = data;
          data.target.dispatchEvent(gestureEvent);
        }

        assign(Hammer, {
          INPUT_START: INPUT_START,
          INPUT_MOVE: INPUT_MOVE,
          INPUT_END: INPUT_END,
          INPUT_CANCEL: INPUT_CANCEL,
          STATE_POSSIBLE: STATE_POSSIBLE,
          STATE_BEGAN: STATE_BEGAN,
          STATE_CHANGED: STATE_CHANGED,
          STATE_ENDED: STATE_ENDED,
          STATE_RECOGNIZED: STATE_RECOGNIZED,
          STATE_CANCELLED: STATE_CANCELLED,
          STATE_FAILED: STATE_FAILED,
          DIRECTION_NONE: DIRECTION_NONE,
          DIRECTION_LEFT: DIRECTION_LEFT,
          DIRECTION_RIGHT: DIRECTION_RIGHT,
          DIRECTION_UP: DIRECTION_UP,
          DIRECTION_DOWN: DIRECTION_DOWN,
          DIRECTION_HORIZONTAL: DIRECTION_HORIZONTAL,
          DIRECTION_VERTICAL: DIRECTION_VERTICAL,
          DIRECTION_ALL: DIRECTION_ALL,
          Manager: Manager,
          Input: Input,
          TouchAction: TouchAction,
          TouchInput: TouchInput,
          MouseInput: MouseInput,
          PointerEventInput: PointerEventInput,
          TouchMouseInput: TouchMouseInput,
          SingleTouchInput: SingleTouchInput,
          Recognizer: Recognizer,
          AttrRecognizer: AttrRecognizer,
          Tap: TapRecognizer,
          Pan: PanRecognizer,
          Swipe: SwipeRecognizer,
          Pinch: PinchRecognizer,
          Rotate: RotateRecognizer,
          Press: PressRecognizer,
          on: addEventListeners,
          off: removeEventListeners,
          each: each,
          merge: merge,
          extend: extend,
          assign: assign,
          inherit: inherit,
          bindFn: bindFn,
          prefixed: prefixed
        }); // this prevents errors when Hammer is loaded in the presence of an AMD
        //  style loader but by script tag, not by the loader.

        var freeGlobal = typeof window !== 'undefined' ? window : typeof self !== 'undefined' ? self : {}; // jshint ignore:line

        freeGlobal.Hammer = Hammer;

        if (typeof undefined$1 === 'function' && undefined$1.amd) {
          undefined$1(function () {
            return Hammer;
          });
        } else if ( module.exports) {
          module.exports = Hammer;
        } else {
          window[exportName] = Hammer;
        }
      })(window, document, 'Hammer');
    });

    function IController (ng) {
      let engine = ng;

      this.getEngine = () => this.engine;

      this.setEngine = ng => this.engine = ng; // let mainSlip = mainS;
      // this.getMainSlip = () => mainSlip;
      // this.setMainSlip = (slip) => mainSlip = slip;


      let mc = new hammer(document.body);
      mc.on("swipe", ev => {
        if (ev.direction == 2) {
          engine.next();
        }

        if (ev.direction == 4) {
          engine.previous();
        }
      });
      let speedMove = 1;
      document.addEventListener("keypress", ev => {
        if (ev.key == "f") {
          speedMove = (speedMove + 4) % 30 + 1;
        }

        if (ev.key == "r") {
          engine.getCurrentSlip().refresh();
        }

        if (ev.key == "#") {
          document.querySelectorAll("slip-slip").forEach(slip => {
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

    function Slip(name, fullName, actionL, ng, options) {
      // ******************************
      // Action List
      // ******************************
      this.generateActionList = function () {
        console.log("debug generateactionlist", this.name);
        let newActionList = [];
        this.queryAll("slip-slip[enter-at]").forEach(slip => {
          console.log("new slip with ", slip, null, null, ng, {});
          newActionList[slip.getAttribute("enter-at")] = new Slip(slip, "", [], ng, {});
        });
        return newActionList;
      };

      this.addSubSlips = function () {
        console.log("debug generateactionlist", this.name);
        let newActionList = [];
        this.queryAll("slip-slip[enter-at]").forEach(slip => {
          console.log("new slip with ", slip, null, null, ng, {});
          this.setNthAction(slip.getAttribute("enter-at"), new Slip(slip, "", [], ng, {}));
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
          if (this.pauseSlipList[i] instanceof Slip) ret[i] = this.pauseSlipList[i];else if (typeof actionList[i] == "function" || actionList[i] instanceof Slip) ret[i] = actionList[i];else ret[i] = () => {};
        }

        return ret;
      };

      this.setNthAction = (n, action) => {
        actionList[n] = action;
      };

      this.getCurrentSubSlip = () => {
        if (actionList[this.getActionIndex()] instanceof Slip) return actionList[this.getActionIndex()];
        if (this.pauseSlipList[this.getActionIndex()] instanceof Slip) return this.pauseSlipList[this.getActionIndex()];
        return false;
      };

      this.nextStageNeedGoto = () => {
        if (actionList[this.getActionIndex() + 1] instanceof Slip) return false;
        if (this.pauseSlipList[this.getActionIndex() + 1] instanceof Slip) return false;
        if (this.getActionIndex() >= this.getMaxNext()) return false;
        return true;
      };

      this.getSubSlipList = function () {
        return this.getActionList().filter(action => action instanceof Slip);
      }; // ******************************
      // Action Index
      // ******************************


      let actionIndex = -1;

      this.setActionIndex = actionI => actionIndex = actionI;

      this.getActionIndex = () => actionIndex;

      this.getMaxNext = () => {
        if (this.maxNext) return this.maxNext;
        let maxTemp = actionList.length;
        ["mk-visible-at", "mk-hidden-at", "mk-emphasize-at", "mk-unemphasize-at", "emphasize-at", "chg-visib-at", "up-at", "down-at", "center-at", "static-at", "exec-at", "enter-at", "focus-at", "unfocus-at"].forEach(attr => {
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
        // let other = Array.from(this.element.querySelectorAll("#"+this.name+" slip "+quer));
        // return allElem.filter(value => !other.includes(value));
      };

      this.query = quer => {
        if (typeof quer != "string") return quer;
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

        while (pause && pause.tagName != "SLIP-SLIP") {
          pause.classList.add("pauseAncestor");
          pause = pause.parentElement;
        }
      };

      this.unpause = pause => {
        if (pause.hasAttribute("down-at-unpause")) {
          if (pause.getAttribute("down-at-unpause") == "") this.moveDownTo(pause, 1);else this.moveDownTo("#" + pause.getAttribute("down-at-unpause"), 1);
        }

        if (pause.hasAttribute("up-at-unpause")) {
          if (pause.getAttribute("up-at-unpause") == "") this.moveUpTo(pause, 1);else this.moveUpTo("#" + pause.getAttribute("up-at-unpause"), 1);
        }

        if (pause.hasAttribute("center-at-unpause")) if (pause.getAttribute("center-at-unpause") == "") this.moveCenterTo(pause, 1);else this.moveCenterTo("#" + pause.getAttribute("center-at-unpause"), 1);
        if (pause.hasAttribute("exec-at-unpause")) if (pause.getAttribute("exec-at-unpause") == "") this.executeScript(pause);else this.executeScript("#" + pause.getAttribute("exec-at-unpause"));
        if (pause.hasAttribute("reveal-at-unpause")) if (pause.getAttribute("reveal-at-unpause") == "") this.reveal(pause);else this.reveal("#" + pause.getAttribute("reveal-at-unpause"));
        if (pause.hasAttribute("focus-at-unpause")) if (pause.getAttribute("focus-at-unpause") == "") this.focus(pause);else this.focus("#" + pause.getAttribute("focus-at-unpause"));
        if (pause.hasAttribute("unfocus-at-unpause")) if (pause.getAttribute("unfocus-at-unpause") == "") this.unfocus(pause);else this.unfocus("#" + pause.getAttribute("unfocus-at-unpause"));
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
              this.unpause(pause);
            } else pause.setAttribute("step", d - 1);
          }

          if (pause.hasAttribute("auto-enter")) {
            pause.setAttribute("auto-enter", 0);
            this.unpause(pause);
          }

          if (pause.hasAttribute("immediate-enter")) {
            pause.setAttribute("immediate-enter", 0);
            this.unpause(pause);
          }

          if (pause.hasAttribute("pause")) {
            if (!pause.getAttribute("pause")) pause.setAttribute("pause", 1);
            let d = pause.getAttribute("pause");

            if (d <= 1) {
              pause.removeAttribute("pause");
              this.unpause(pause);
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
          if (actionIndex < 0) return;

          if (staticAt.includes(-actionIndex)) {
            console.log("make unstatic actionIndex elem", actionIndex, elem);
            this.makeUnStatic(elem); // elem.style.position = "absolute";
            // elem.style.visibility = "hidden";
          } else if (staticAt.includes(actionIndex)) {
            this.makeStatic(elem); // elem.style.position = "static";
            // elem.style.visibility = "visible";
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
        this.queryAll("*[focus-at]").forEach(elem => {
          let focus = elem.getAttribute("focus-at").split(" ").map(str => parseInt(str));
          if (focus.includes(actionIndex)) this.focus(elem, 1);
        });
        this.queryAll("*[unfocus-at]").forEach(elem => {
          let focus = elem.getAttribute("unfocus-at").split(" ").map(str => parseInt(str));
          if (focus.includes(actionIndex)) this.unfocus(elem, 1);
        });
        this.queryAll("*[exec-at]").forEach(elem => {
          let toExec = elem.getAttribute("exec-at").split(" ").map(str => parseInt(str));
          if (toExec.includes(actionIndex)) this.executeScript(elem);
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

        if (actionList[actionIndex] instanceof Slip) {
          return actionList[actionIndex];
        }

        if (this.pauseSlipList[actionIndex] instanceof Slip) return this.pauseSlipList[actionIndex]; // let nextSlip = this.query("[pause], [auto-enter]");
        // if(nextSlip.hasAttribute("auto-enter"))
        //     return 

        return true;
      };

      this.previous = () => {
        let savedActionIndex = this.getActionIndex();
        let savedDelay = this.currentDelay;
        this.getEngine().setDoNotMove(true);
        console.log("gotoslip: we call doRefresh", this.doRefresh());
        if (savedActionIndex == -1) return false;
        let toReturn;

        while (this.getActionIndex() < savedActionIndex - 1) {
          console.log("previous is ca we do next", this.getEngine().getDoNotMove());
          toReturn = this.next();
        } // if(!this.nextStageNeedGoto())
        //     this.getEngine().setDoNotMove(false);
        // while(this.getActionIndex()<savedActionIndex-1)
        //     toReturn = this.next();


        setTimeout(() => {
          this.getEngine().setDoNotMove(false);
        }, 0);
        this.getEngine().gotoSlip(this, {
          delay: savedDelay
        });
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
        }); // this.queryAll("*[static-at]").forEach((elem) => {
        //     elem.style.position = "absolute";
        //     elem.style.visibility = "hidden";
        // });	
        //	this.doAttributes();

        this.updatePauseAncestors();
        if (options.init) options.init(this);
      }; // ******************************
      // Refreshes
      // ******************************


      this.refresh = () => {
        if (actionList[actionIndex] instanceof Slip) actionList[actionIndex].refresh();else this.doRefresh();
      };

      this.refreshAll = () => {
        actionList.filter(elem => elem instanceof Slip).forEach(subslip => {
          subslip.refreshAll();
        });
        this.pauseSlipList.filter(elem => elem instanceof Slip).forEach(subslip => {
          subslip.refreshAll();
        });
        this.doRefresh();
      };

      this.doRefresh = () => {
        console.log("gotoslip: doRefresh has been called");
        this.setActionIndex(-1);
        let subSlipList = myQueryAll(this.element, "slip-slip");
        console.log("mmdebug", clonedElement);
        let clone = clonedElement.cloneNode(true);
        replaceSubslips(clone, subSlipList);
        this.element.replaceWith(clone);
        this.element = clone;
        this.init();
        this.firstVisit();
        delete this.currentX;
        delete this.currentY;
        delete this.currentDelay;
        console.log("previous is ca GOTOSLIP FROM 3", options, this.getEngine().getDoNotMove());
        this.getEngine().gotoSlip(this);
      }; // ******************************
      // Movement, execution and hide/show
      // ******************************


      this.makeUnStatic = (selector, delay, opacity) => {
        let elem = this.query(selector); // setTimeout(() => {
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

      this.makeStatic = selector => {
        let elem = this.query(selector);
        elem.style.position = "static";
        elem.style.visibility = "visible";
      };

      this.unfocus = selector => {
        this.getEngine().gotoSlip(this, {
          delay: 1
        });
      };

      this.focus = selector => {
        let elem = this.query(selector);
        this.getEngine().moveToElement(elem, {});
      };

      this.executeScript = selector => {
        let elem;
        if (typeof selector == "string") elem = this.query(selector);else elem = selector;
        new Function("slip", elem.innerHTML)(this);
      };

      this.moveUpTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0.0125;
          let coord = this.findSlipCoordinate();
          let d = (elem.offsetTop / 1080 - offset) * coord.scale;
          this.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay); // this.currentX = coord.x;
          // this.currentY = coord.y+d;
          // this.currentDelay = delay;
          // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.moveDownTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0.0125;
          let coord = this.findSlipCoordinate();
          let d = ((elem.offsetTop + elem.offsetHeight) / 1080 - 1 + offset) * coord.scale;
          this.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay); // this.currentX = coord.x;
          // this.currentY = coord.y+d;
          // this.currentDelay = delay;
          // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.moveCenterTo = (selector, delay, offset) => {
        setTimeout(() => {
          let elem;
          if (typeof selector == "string") elem = this.query(selector);else elem = selector;
          if (typeof offset == "undefined") offset = 0;
          let coord = this.findSlipCoordinate();
          let d = ((elem.offsetTop + elem.offsetHeight / 2) / 1080 - 1 / 2 + offset) * coord.scale;
          this.moveWindow(coord.x, coord.y + d, coord.scale, this.rotate, delay); // this.currentX = coord.x;
          // this.currentY = coord.y+d;
          // this.currentDelay = delay;
          // engine.moveWindow(coord.x, coord.y+d, coord.scale, this.rotate, delay);
        }, 0);
      };

      this.restoreWindow = () => {
        this.getEngine;
      };

      this.moveWindow = (x, y, scale, rotate, delay) => {
        this.currentX = x;
        this.currentY = y;
        this.currentDelay = delay;
        console.log("previous is ca we try to move win", this.getEngine().getDoNotMove());
        console.log("previous is ca ORIGIN 3", x, y, this.getEngine().getDoNotMove()); //	setTimeout(() => {

        this.getEngine().moveWindow(x, y, scale, rotate, delay); //	}, 0);
      };

      this.reveal = selector => {
        let elem;
        if (typeof selector == "string") elem = this.query(selector);else elem = selector;
        elem.style.opacity = "1";
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
      // engine


      let engine = ng;

      this.getEngine = () => engine;

      this.setEngine = ng => engine = ng; // element


      this.element = typeof name == "string" ? document.querySelector(name[0] == "#" ? name : "#" + name) : name; // names

      this.name = typeof name == "string" ? name : name.id;
      if (typeof fullName == "string") this.fullName = fullName;else if (this.element.hasAttribute("toc-title")) this.fullName = this.element.getAttribute("toc-title");else this.fullName = this.name;
      console.log("this name is ", this.name); // clonedElement

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
            slipList[step] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
            step++;
          }

          if (elem.hasAttribute("immediate-enter")) {
            // the slip is entered before the pause
            slipList[step - 1] = new Slip(elem, elem.getAttribute("toc-title") || "", [], ng, {});
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

    function IEngine (root) {
      function prepareRoot(rootElem) {
        let container = document.createElement("div");
        container.innerHTML = '	\
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
        rootElem.querySelectorAll("slip-slip").forEach(slipElem => {
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

      if (typeof root == "string") {
        if (root[0] != "#") root = "#" + root;
        root = document.querySelector(root);
      } else if (typeof root == "undefined") root = document.querySelector("slip-slipshow");

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
      let slips = universe.querySelectorAll("slip-slip:not(slip-slipshow)");
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
          console.log("previous is ca we cannot move !");
          return;
        }

        console.log("previous is ca getDoNotMove !", x, y, scale, rotate, delay, this.getDoNotMove());
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
          let subslips = myQueryAll(elem, "slip-slip");
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

      this.previous = options => {
        console.log("previous is called with option", options);
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
          console.log("previous is ca GOTOSLIP FROM 1", options);
          this.gotoSlip(n, options); // this.gotoSlip(n, {delay: currentSlip.delay});
          // this.showToC();

          this.updateCounter();
          return true;
        } else if (!n) {
          this.pop();
          let newCurrentSlide = this.getCurrentSlip(); // newCurrentSlide.incrIndex();

          console.log("previous is ca currentDelay, delay", currentSlip.currentDelay, currentSlip.delay);
          if (stack.length > 1 || newCurrentSlide.getActionIndex() > -1) this.previous({
            delay: currentSlip.currentDelay ? currentSlip.currentDelay : currentSlip.delay
          });else {
            this.gotoSlip(newCurrentSlide, options);
            console.log("previous is ca GOTOSLIP FROM 2", options);
          } // this.gotoSlip(newCurrentSlide, {delay: currentSlip.delay});
          // console.log(stack);
          // this.showToC();

          this.updateCounter();
          return true;
        } else if (options) {
          setTimeout(() => {
            this.gotoSlip(currentSlip, options);
          }, 0);
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
        console.log("previous is ca goto slip", options, slip.element, this.getDoNotMove());
        console.log("we goto slip", slip.element, this.getDoNotMove());
        options = options ? options : {};
        console.log("options is ", options);

        if (slip.element.tagName == "SLIP-SLIP") {
          setTimeout(() => {
            let coord = slip.findSlipCoordinate();

            if (typeof slip.currentX != "undefined" && typeof slip.currentY != "undefined") {
              console.log("previous is ca ORIGIN 1", slip.currentX, slip.currentY, this.getDoNotMove(), options);
              this.moveWindow(slip.currentX, slip.currentY, coord.scale, slip.rotate, typeof options.delay != "undefined" ? options.delay : typeof slip.currentDelay != "undefined" ? slip.currentDelay : slip.delay);
            } else {
              slip.currentX = coord.x;
              slip.currentY = coord.y;
              slip.currentDelay = slip.delay;
              console.log("previous is ca ORIGIN 2", coord.x, coord.y, this.getDoNotMove());
              this.moveWindow(coord.x, coord.y, coord.scale, slip.rotate, typeof options.delay != "undefined" ? options.delay : typeof slip.currentDelay != "undefined" ? slip.currentDelay : slip.delay);
            }
          }, 0);
        } else {
          setTimeout(() => {
            console.log("debug slip element", slip.element);
            let coord = this.getCoordinateInUniverse(slip.element);
            this.moveWindow(coord.centerX, coord.centerY, Math.max(coord.width, coord.height), 0, typeof options.delay != "undefined" ? options.delay : slip.delay);
          }, 0);
        }
      };

      let rootSlip = new Slip(root, "Presentation", [], this, {});
      let stack = [rootSlip]; // Stack Management:

      this.push = function (n) {
        this.getToC().querySelectorAll(".toc-slip .active-slip").forEach(elem => elem.classList.remove("active-slip"));
        if (n.tocElem) n.tocElem.classList.add("active-slip");
        stack.push(n);
        return;
      };

      this.pop = function () {
        this.getToC().querySelectorAll(".toc-slip .active-slip").forEach(elem => elem.classList.remove("active-slip"));
        let n = stack.pop();
        if (stack.length == 0) stack.push(n);
        if (stack[stack.length - 1].tocElem) stack[stack.length - 1].tocElem.classList.add("active-slip");
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

      let toc;

      this.getToC = function () {
        if (toc) return toc;
        toc = document.querySelector(".toc-slip");
        return toc;
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

          nameElement.innerText = tree.slip.fullName; //? tree.slip.fullName : tree.slip.name ; //+ " (" + (tree.slip.getActionIndex()+1) + "/" + (tree.slip.getMaxNext()+1) + ")";

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
      if (typeof MathJax != "undefined") MathJax.startup.promise.then(() => {
        engine = new Engine(document.querySelector("slip-slipshow")).start();
      });else engine = new Engine(document.querySelector("slip-slipshow")).start();
      return engine;
    };
    /**
     * Allows slip-js to be used as simple CDN-included file
     */
    // window.Engine = IEngine;
    // window.Controller = IController;
    // window.Slip = ISlip;
    // window.Util = IUtil;

    exports.Controller = Controller;
    exports.Engine = Engine;
    exports.Slip = Slip$1;
    exports.Util = Util;
    exports.startSlipshow = startSlipshow;

    return exports;

}({}));
//# sourceMappingURL=slipshow.cdn.js.map
