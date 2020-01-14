import IEngine from './modules/engine'
import IController from './modules/controller.mjs'
import ISlip from './modules/slip'
import * as IUtil from './modules/util'

/**
 * Allows slip-js to be used as a module
 */
export const Engine = IEngine;
export const Controller = IController;
export const Slip = ISlip;
export const Util = IUtil;

/**
 * Allows slip-js to be used as simple CDN-included file
 */
window.Engine = IEngine;
window.Controller = IController;
window.Slip = ISlip;
window.Util = IUtil;