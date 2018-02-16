PROJECT=test_project


REBAR3 = rebar3

run: deps compile release console

clean: clean_all

deps:
	@$(REBAR3) get-deps

compile:
	@$(REBAR3) compile

release:
	@$(REBAR3) release -n $(PROJECT)

production_release:
	@$(REBAR3) as production release -n $(PROJECT)

test_release:
	@$(REBAR3) as test release -n $(PROJECT)

console:
	./_build/default/rel/$(PROJECT)/bin/$(PROJECT) console

clean_all:
	rm -rf ./_build


