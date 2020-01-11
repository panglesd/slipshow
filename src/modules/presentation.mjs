import Slip from './slip'

export default function (ng, ls) {
    if(!ls)
	ls = Array.from(document.querySelectorAll(".slip")).map((elem) => { return new Slip(elem.id, [], this, ng, {});});
    console.log(ls);
    // let cpt = 0;
    // Taken from https://selftaughtjs.com/algorithm-sundays-converting-roman-numerals
    // Use in showing roman numbers for slip number
    function toRoman(num) {
	var result = '';
	var decimal = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
	var roman = ["M", "CM","D","CD","C", "XC", "L", "XL", "X","IX","V","IV","I"];
	for (var i = 0;i<=decimal.length;i++) {
	    while (num%decimal[i] < num) {     
		result += roman[i];
		num -= decimal[i];
	    }
	}
	return result;
    }
    this.getCpt = () => {
	return [
	    this.getSlips().findIndex((slip) => {return slip == this.getCurrentSlip();}),
	    this.getCurrentSlip().getActionIndex()
	];
    };
    this.setCpt = () => {
	let cpt = this.getCpt();
	document.querySelector(".cpt-slip").innerText = (toRoman(cpt[0]+1)+"."+(cpt[1]+1));
    };
    let engine = ng;
    this.getEngine = () => this.engine;
    this.setEngine = (ng) => this.engine = ng;
    let listSlips = ls || [];
    let slipIndex = 0;
    this.getSlips = () => listSlips;
    this.setSlips = (ls) => listSlips = ls;
    this.getCurrentSlip = () => listSlips[slipIndex];
    this.gotoSlip = function(slip, options) {
	options = options ? options : {};
	console.log("options is ", options);
	// let x = slip.x, y = slip.y;
	// let scale = slip.scale, rotate = slip.rotate, delay = slip.delay;
	// console.log(x,y, scale, rotate);
	setTimeout(() => {
	    engine.moveWindow(slip.currentX, slip.currentY, slip.scale, slip.rotate, options.delay ? options.delay : slip.delay);
	},0);
    };
    this.gotoSlipIndex = (index, options) => {
	// if(!listSlips[slipIndex].element.classList.contains("permanent"))
	//     listSlips[slipIndex].element.style.zIndex = "-1";
	slipIndex = index;
	// listSlips[slipIndex].element.style.zIndex = "1";
	this.gotoSlip(listSlips[slipIndex], options);
	if(!listSlips[slipIndex].visited) {
	    listSlips[slipIndex].visited = true;
	    listSlips[slipIndex].firstVisit(this);
	}
    };
    this.next = () => {
	// listSlips[slipIndex].currentCpt = cpt;
	let flag;
	if((flag = !listSlips[slipIndex].next(this))) {
	    if(slipIndex<listSlips.length-1)
		this.gotoSlipIndex(slipIndex+1);
	}
	this.setCpt();
	//	cpt++;
	// let cpt = this.getCpt();
	// document.querySelector(".cpt-slip").innerText = (toRoman(cpt[0])+"."+(cpt[1]));
	return flag;
    };
    this.nextSlip = () => {
	if(!this.next())
	    this.nextSlip();
    };
    this.skipSlip = (options) => {
	this.gotoSlipIndex(slipIndex+1, options);
	this.setCpt();
    };
    this.previousSlip = () => {
	slipIndex = Math.max(0, slipIndex -1);
	this.gotoSlip(listSlips[slipIndex]);
	this.setCpt();
	// cpt = listSlips[slipIndex].currentCpt;
	// document.querySelector(".cpt-slip").innerText = (cpt);
    };
    this.previous = () => {
	let saveCpt = this.getCurrentSlip().getActionIndex();
	this.refresh();
	if(saveCpt == 0)
	    this.previousSlip();
	else
	    while(this.getCurrentSlip().getActionIndex()<saveCpt-1)
		this.next();
	this.setCpt();
    };
    this.refresh = () => {
	listSlips[slipIndex].refresh();
	this.gotoSlip(listSlips[slipIndex]);
	// cpt = listSlips[slipIndex].initCpt;
	// document.querySelector(".cpt-slip").innerText = (cpt);
	this.setCpt();
    };
    this.start = () => {
	slipIndex = 0;
	this.gotoSlip(listSlips[slipIndex]);
	listSlips[slipIndex].element.style.zIndex = "1";
	listSlips[slipIndex].firstVisit(this);
	// listSlips[slipIndex].initCpt = cpt;
	// listSlips[slipIndex].currentCpt = cpt;
	this.setCpt();
    };
};
