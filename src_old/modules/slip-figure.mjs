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
