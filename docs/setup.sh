opam exec -- dune build --profile release doc-repl/main.js
cp doc-repl/main.js _static/main.js

opam exec -- dune build --profile release @../example/examples

mkdir -p extra_html/campus-du-libre
cp ../example/campus-du-libre/cdl.html extra_html/campus-du-libre/cdl.html

mkdir -p extra_html/edge-documentation
cp ../example/edge-documentation/doc.html extra_html/edge-documentation/doc.html

mkdir -p extra_html/undo-monad-short
cp ../example/undo-monad-short/pres.html extra_html/undo-monad-short/pres.html

mkdir -p extra_html/funocaml-2025
cp ../example/funocaml-2025/main.html extra_html/funocaml-2025/main.html
