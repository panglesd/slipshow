opam exec -- dune build --profile release doc-repl/main.js
cp doc-repl/main.js _static/main.js

opam exec -- dune build --profile release @../example/cdl/examples
mkdir -p extra_html
cp ../example/cdl/cdl.html extra_html/cdl.html
