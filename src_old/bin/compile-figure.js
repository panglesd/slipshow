#!/usr/bin/env node

var shell = require('shelljs');
var appRoot = require('app-root-path');
var readlineSync = require('readline-sync');

function doFigure(fig) {
    console.log("Figure "+fig);
    shell.cd(appRoot+"/figures/"+fig);
    console.log("Compiling...");
    shell.exec("pdflatex -shell-escape "+fig+".tex");
    console.log("Converting subfigures...");
    shell.ls(fig+"-figure*.pdf").forEach((subfigure,i) => {
	shell.exec("pdf2svg "+subfigure+" "+fig+("_"+i+".svg"));
	console.log('Outputed '+fig+("_"+i+".svg"));
    });    
}
function doAllFigures() {
    shell.ls(appRoot+"/figures/").forEach((fig) => {
	doFigure(fig);	
    });    
}

if(process.argv.includes("--help")) {
    console.log("This script requires pdflatex and pdf2svg to work")
    console.log("Usage: npx compile-figure [--all] [figure-name] [--help]")
}
else if(process.argv.includes("--all")) {
    doAllFigures()
}
else if (process.argv.length > 2) {
    process.argv.forEach((fig) => {
	if(!fig.includes("/"))
	    doFigure(fig);	
    });
console.log("This script requires pdflatex and pdf2svg to work");
}
else {
    let figTranslation = shell.ls(appRoot+"/figures/");
    figTranslation.forEach((fig, index) => {
	console.log(index, fig)
    });
    var listFigures = readlineSync.question('What figure do you want to compile? (empty for all, spaces for multiple answers): ');
    listFigArray = listFigures.split(" ");
    if(listFigures == "")
	doAllFigures()
    else
	listFigArray.forEach((figNumber) => {
	    doFigure(figTranslation[parseInt(figNumber)])
	})
}
