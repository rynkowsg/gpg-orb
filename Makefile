.PHONY: deps _format_deps format format-check _lint_deps lint gen

deps:
	sosh fetch src/scripts/setup.bash

_format_deps: @bin/format.bash
	sosh fetch @bin/format.bash

format-check: _format_deps
	\@bin/format.bash check

format: _format_deps
	\@bin/format.bash apply

_lint_deps: @bin/lint.bash
	sosh fetch @bin/lint.bash

lint: _format_deps _lint_deps deps
	\@bin/lint.bash

gen: deps
	sosh pack -i src/scripts/setup.bash -o src/scripts/gen/setup.bash
