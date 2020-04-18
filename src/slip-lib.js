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

export let startSlipshow = () => {
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
