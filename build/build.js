var shell = require('shelljs')

shell.rm('-r', 'dist')

// shell.exec('node-sass -r src/themes -o dist/themes')
shell.mkdir("dist");
shell.cp('-r', 'src/css', 'dist/css');
shell.exec('rollup -c build/rollup.config.js');
