import './modules/slip-figure'

import IEngine from './modules/engine'
import IController from './modules/controller.mjs'
import ISlip from './modules/slip'
import * as IUtil from './modules/util'

// import "./css/slip.css";
// import "./css/theorem.css";

/**
 * Allows slip-js to be used as a module
 */
export const Engine = IEngine;
export const Controller = IController;
export const Slip = ISlip;
export const Util = IUtil;

export let startSlipshow = async () => {
    let engine;
    if(typeof MathJax != "undefined")
	return MathJax.startup.promise.then(() => {
	    engine = new Engine(document.querySelector("slip-slipshow")).start();
	    return Promise.resolve(engine);
	});
    else
	engine = new Engine(document.querySelector("slip-slipshow")).start();
    return Promise.resolve(engine);
};

/**
 * Allows slip-js to be used as simple CDN-included file
 */
// window.Engine = IEngine;
// window.Controller = IController;
// window.Slip = ISlip;
// window.Util = IUtil;
