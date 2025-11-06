all:
	dune build

clean:
	dune clean

TESTS=minimal misc reranger stress pretty \
			cbor/cbor_of_fs cbor/cbor_explorer
RUN_TESTS_BC=$(patsubst %, run-%, $(TESTS))
RUN_TESTS_EXE=$(patsubst %, run-%.exe, $(TESTS))

$(TESTS):
	dune build examples/$@.bc

examples:
	dune build $(patsubst	%,examples/%.bc,$(TESTS))

$(RUN_TESTS_BC):
	dune exec examples/$(patsubst run-%,%,$@.bc)

$(RUN_TESTS_EXE):
	dune exec examples/$(patsubst run-%,%,$@)

run-cbor-explorer.exe:
	rm curdir.cbor || true
	dune exec examples/cbor/cbor_of_fs.exe -- -o curdir.cbor ./
	dune exec examples/cbor/cbor_explorer.exe -- curdir.cbor

.PHONY: all clean examples $(RUN_TESTS_BC) $(RUN_TESTS_EXE)
