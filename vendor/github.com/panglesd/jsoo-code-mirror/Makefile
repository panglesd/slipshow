.PHONY: example node bundle fmt
example:
	dune build --ignore-promoted-rules
	parcel _build/default/example/src/index.html

node:
	npm install

# Use that command if you want to re-generate the static bundled in the includes
# folder, for example if there was an update of code-mirror.
bundle: node
	dune build --profile=with-bundle

fmt:
	dune build @fmt --auto-promote
