BIN=$(RAILS_ASYNC)/bin
TESTS=$(shell $(BIN)/test_tasks)

all: $(TESTS)
	$(BIN)/conclusion.rb $(TESTS)

setup:
	mkdir -vp log run
	rm -f log/*.out log/*.err run/*.fail run/*.setup

$(TESTS): setup
	$(BIN)/suite.rb "$@" || touch "run/$@.fail"
