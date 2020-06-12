#!/usr/bin/env node

var shell = require('shelljs');
var readlineSync = require('readline-sync');
var appRoot = require('app-root-path');
var fs = require('fs');

shell.cd(appRoot)
shell.mkdir("-p","figures")
shell.cd("figures")

console.log("For your information, here is a list of your other figures:")
console.log(shell.ls()) // ?

var figureName = readlineSync.question('What do you want your new figure to be called? ');
//console.log("What do you want your new figure to be called?")

shell.mkdir(figureName)
shell.cd(figureName)
let figureFile = "\n\
\documentclass[beamer]{standalone}\n\
\usepackage{tikz}\n\
\usetikzlibrary{external}\n\
\tikzexternalize % activate! \n\
\begin{document}\n\
\begin{standaloneframe}\n\
\n\
% If overlays do not work, use \only<1-n>{...} where n is the max overlay\n\
% \only<1-1000>{\n\
  \begin{tikzpicture}[]\n\
	% ...   \n\
  \end{tikzpicture}\n\
% }\n\
\end{standaloneframe}\n\
\end{document}\n\
"


fs.appendFile(appRoot+"/figures/"+figureName+"/"+figureName+".tex", figureFile, function (err) {
  if (err) throw err;
  console.log('File written in '+appRoot+"/figures/"+figureName+"/"+figureName+".tex");
  console.log('Edit this file to your need,');
  console.log('and then compile it using npx compile-figure '+figureName+" (or npx compile-figure --all to compile all figures)");
//  console.log('or pdflatex -shell-escape '+figureName+".tex in the corresponding directory");
}); 


// console.log(appRoot.toString())


// let template = '\n\
// <!DOCTYPE html>\n\
// <html lang="fr">\n\
//   <head>\n\
//     <meta charset="UTF-8">\n\
// \n\
//     <title>Slipshow</title>\n\
// \n';
// if(process.argv.includes("--cdn"))
//     template += '\
// '
// else
//     template += '\
//     <link rel="stylesheet" type="text/css" href="node_modules/slipshow/dist/css/slip.css">\n\
//     <link rel="stylesheet" type="text/css" href="node_modules/slipshow/dist/css/theorem.css">\n\
// '
// if(process.argv.includes("--mathjax-cdn"))
//     template += "<!-- TODO -->";
// if(process.argv.includes("--mathjax-local"))
//     template += '    <script src="node_modules/mathjax/es5/tex-chtml.js" id="MathJax-script" async></script>\n';

// template += '  <body>\n\
// \n\
//     <!-- This is the presentation -->\n\
//     <slip-slipshow>\n\
// \n\
//       <!-- Add the slips here -->\n\
// \n\
//       <!-- For instance here is a slip -->\n\
//       <slip-slip immediate-enter toc-title="Example of a slip">\n\
// 	<slip-title>The first slip of your presentation</slip-title>\n\
// 	<slip-body>\n\
//           Example\n\
// 	</slip-body>\n\
//       </slip-slip>\n\
//       <!-- End of slip "Example of a slip" -->\n\
// \n\
//     </slip-slipshow>\n\
// \n\
//     <!-- Include the library -->\n\
// ';
// if(process.argv.includes("--cdn"))
//     template += '\
// '
// else
//     template += '\
//     <script src="node_modules/slipshow/dist/slipshow.cdn.js"></script>\n\
// '
// template += '\
//     <!-- Start the presentation () -->\n\
//     <script>\n\
//       let engine = Slipshow.startSlipshow();\n\
//     </script>\n\
//   </body>\n\
// </html>\n\
// '
// ;
// template = process.env.PWD
// console.log(template)

