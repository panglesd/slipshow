var shell = require('shelljs')

shell.rm('-r', 'staged_dist')

// shell.exec('node-sass -r src/themes -o dist/themes')
shell.mkdir("staged_dist");
shell.mkdir("bin");
shell.cp('-r', 'src/css', 'staged_dist/css');
shell.cp('-r', 'example', 'staged_dist/example');
shell.exec('rollup -c build/rollup.config.mjs');

// shell.exec('mkdir tmp; cd tmp; mkdir slipshow; cd slipshow; echo "{}" > package.json ; npm install slipshow; npm install mathjax@3; npx new-slipshow --mathjax > slipshow.html ; cd .. ; tar zcvf slipshow.tar.gz slipshow ; cd .. ; cp tmp/slipshow.tar.gz dist; rm -rf tmp ');
