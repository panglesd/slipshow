.PHONY: node bundle

node:
	npm install

# Use that command if you want to re-generate the static bundled in the includes
# folder, for example if there was an update of code-mirror.
bundle: node
	dune build --profile=with-bundle --auto-promote @data-files
