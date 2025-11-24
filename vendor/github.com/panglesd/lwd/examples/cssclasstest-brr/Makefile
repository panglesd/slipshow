ROOT=$(realpath $(PWD)/../..)
NAME=$(subst $(ROOT)/,,$(realpath $(PWD)))

all:
	dune build index.html main.js
	@echo "open $(ROOT)/_build/default/$(NAME)/index.html"

clean:
	dune clean
