var shell = require('shelljs')

shell.exec('rm -rf tmp; mkdir tmp; cd tmp; mkdir slipshow; cd slipshow; echo "{}" > package.json ; npm install slipshow; npm install mathjax@3; npx new-slipshow --mathjax > slipshow.html ; cd .. ; tar zcvf slipshow.tar.gz slipshow ; cd .. ; cp tmp/slipshow.tar.gz dist; rm -rf tmp ');
