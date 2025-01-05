TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test

test:
	@nvim -l tests/minit.lua --minitest
