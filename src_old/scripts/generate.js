#!/usr/bin/env node

let template = '\n\
<!DOCTYPE html>\n\
<html lang="fr">\n\
  <head>\n\
    <meta charset="UTF-8">\n\
\n\
    <title>Slipshow</title>\n\
\n';
if(process.argv.includes("--cdn"))
    template += '\
'
else
    template += '\
    <link rel="stylesheet" type="text/css" href="node_modules/slipshow/dist/css/slip.css">\n\
    <link rel="stylesheet" type="text/css" href="node_modules/slipshow/dist/css/theorem.css">\n\
'
if(process.argv.includes("--mathjax-cdn"))
    template += "<!-- TODO -->";
if(process.argv.includes("--mathjax-local"))
    template += '    <script src="node_modules/mathjax/es5/tex-chtml.js" id="MathJax-script" async></script>\n';

template += '  <body>\n\
\n\
    <!-- This is the presentation -->\n\
    <slip-slipshow>\n\
\n\
      <!-- Add the slips here -->\n\
\n\
      <!-- For instance here is a slip -->\n\
      <slip-slip immediate-enter toc-title="Example of a slip">\n\
	<slip-title>The first slip of your presentation</slip-title>\n\
	<slip-body>\n\
          Example\n\
	</slip-body>\n\
      </slip-slip>\n\
      <!-- End of slip "Example of a slip" -->\n\
\n\
    </slip-slipshow>\n\
\n\
    <!-- Include the library -->\n\
';
if(process.argv.includes("--cdn"))
    template += '\
'
else
    template += '\
    <script src="node_modules/slipshow/dist/slipshow.cdn.js"></script>\n\
'
template += '\
    <!-- Start the presentation () -->\n\
    <script>\n\
      let engine = Slipshow.startSlipshow();\n\
    </script>\n\
  </body>\n\
</html>\n\
'
;
console.log(template)
