#!/usr/bin/env node

var shell = require('shelljs');
var readlineSync = require('readline-sync');
var appRoot = require('app-root-path');
var fs = require('fs');

shell.cd(appRoot.path)
shell.mkdir("figures")
shell.cd("figures")

console.log("For your information, here is a list of your other figures:")
console.log(shell.ls().stdout) // ?

var figureName = readlineSync.question('What do you want your new figure to be called? ');
//console.log("What do you want your new figure to be called?")

shell.mkdir(figureName)
shell.cd(figureName)
let figureFile = "\n\
\\documentclass[beamer]{standalone}\n\
\\usepackage{tikz}\n\
\\usetikzlibrary{external}\n\
\\tikzexternalize % activate! \n\
\\begin{document}\n\
\\begin{standaloneframe}\n\
\n\
% If overlays do not work, use \\only<1-n>{...} where n is the max overlay\n\
% \\only<1-1000>{\n\
  \\begin{tikzpicture}[]\n\
	% ...   \n\
  \\end{tikzpicture}\n\
% }\n\
\\end{standaloneframe}\n\
\\end{document}\n\
"


fs.appendFile(appRoot+"/figures/"+figureName+"/"+figureName+".tex", figureFile, function (err) {
  if (err) throw err;
  console.log('File written in '+appRoot+"/figures/"+figureName+"/"+figureName+".tex");
  console.log('Edit this file to your need,');
  console.log('and then compile it using npx compile-figure '+figureName+" (or npx compile-figure --all to compile all figures)");
//  console.log('or pdflatex -shell-escape '+figureName+".tex in the corresponding directory");
}); 


