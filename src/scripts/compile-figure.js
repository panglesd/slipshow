#!/usr/bin/env node

var shell = require('shelljs');
var appRoot = require('app-root-path');

console.log("This script requires pdflatex and pdf2svg to work");

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

if(process.argv.includes("--all")) {
    shell.ls(appRoot+"/figures/").forEach((fig) => {
	doFigure(fig);	
    });
}
else {
    process.argv.forEach((fig) => {
	doFigure(fig);	
    });
}


