class SlipFigure extends HTMLImageElement {
    // Pour spécifier les attributs qui, changés, appellent "attributeChangedCallback"
    static get observedAttributes() {return ['figure-name']; };

    constructor() {
	// Toujours appeler "super" d'abord dans le constructeur
	super();
	this.internalStep = 0;
	this.img = [];
	this.maxStep = 0;
	// Ecrire la fonctionnalité de l'élément ici
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
	this.preloadImage(i).then(()=> {
	    this.preloadImages(i+1);
	}).catch(() => {
	    this.maxStep = i-1;
	    console.log("Stopping at image", i); 
	});
    }
    connectedCallback() {
	this.figureName = this.getAttribute("figure-name");
	this.updateSRC();
	let i=0;
	this.preloadImages(i);
    }

    getURL(i) {
	return "figures/"+this.figureName+"/"+this.figureName+"_"+i+".svg";
    }
    updateSRC() {
	this.src = this.getURL(this.figureStep);
    }
    
    set figureStep(step) {
	if(step > this.maxStep)
	    this.internalStep = this.maxStep;
	else if (step < 0)
	    this.internalStep = 0;
	else
	    this.internalStep=step;
	this.updateSRC();
    }
    get figureStep() {
	return this.internalStep;
    }
    
    attributeChangedCallback(name, oldValue, newValue) {
	if(name == "figure-name") {
	    this.figureName = this.getAttribute("figure-name");
	    this.preloadImages(0);
	    this.updateSRC();
	}
    }
    nextFigure() {
	this.figuresStep++;
    }
}

customElements.define('slip-figure', SlipFigure, { extends: "img" });
