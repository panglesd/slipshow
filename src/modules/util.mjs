export let myQueryAll = (root, selector, avoid) => {
    avoid = avoid || "slip-slip";
    if (!root.id)
	root.id = '_' + Math.random().toString(36).substr(2, 15);;
    let allElem = Array.from(root.querySelectorAll(selector));
    let separatedSelector = selector.split(",").map(selec => "#"+root.id+" " + avoid + " " + selec).join();
    let other = Array.from(root.querySelectorAll(separatedSelector));
    // let other = Array.from(root.querySelectorAll("#"+root.id+" " + avoid + " " + separatedSelector));
    return allElem.filter(value => !other.includes(value));
};
window.myQueryAll = myQueryAll;

export function cloneNoSubslip (elem) {
    let newElem = elem.cloneNode(false);
    elem.childNodes.forEach((child) => {
	if(child.tagName && child.tagName == "SLIP-SLIP"){
	    let placeholder = document.createElement(child.tagName);
	    let importantAttributes =["pause","step", "auto-enter", "immediate-enter"];
	    importantAttributes.forEach((attr) => {
		if(child.hasAttribute(attr))
		    placeholder.setAttribute(attr, child.getAttribute(attr));
	    });
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
    return newElem;
}
export function replaceSubslips(clone, subslips, sketchpad, sketchpadHighlight) {
    let placeholders = myQueryAll(clone, ".toReplace");
    subslips.forEach((subslip, index) => {
	let importantAttributes =["pause","step", "auto-enter", "immediate-enter"];
	importantAttributes.forEach((attr) => {
	    if(placeholders[index].hasAttribute(attr))
		subslip.setAttribute(attr, placeholders[index].getAttribute(attr));
	});
	placeholders[index].replaceWith(subslip);
    });
    let sketchPlaceholder = myQueryAll(clone, ".toReplaceSketchpad");
    if(sketchPlaceholder[0])
	sketchPlaceholder[0].replaceWith(sketchpad);
    if(sketchPlaceholder[1])
	sketchPlaceholder[1].replaceWith(sketchpadHighlight);
}
