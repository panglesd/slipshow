var shell = require('shelljs')

shell.rm('-r', 'dist')
shell.rm('-r', 'bin')

// shell.exec('node-sass -r src/themes -o dist/themes')
shell.mkdir("dist");
shell.mkdir("bin");
shell.cp('-r', 'src/css', 'dist/css');
shell.cp('-r', 'src/scripts/*', 'bin');
shell.cp('-r', 'example', 'dist/example');
shell.exec('rollup -c build/rollup.config.js');

// shell.exec('mkdir tmp; cd tmp; mkdir slipshow; cd slipshow; echo "{}" > package.json ; npm install slipshow; npm install mathjax@3; npx new-slipshow --mathjax > slipshow.html ; cd .. ; tar zcvf slipshow.tar.gz slipshow ; cd .. ; cp tmp/slipshow.tar.gz dist; rm -rf tmp ');
