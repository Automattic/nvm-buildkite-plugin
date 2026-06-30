test:
	bash tests/nvm-plugin-helpers-test.sh
	bash tests/pre-command-smoke-test.sh

validate:
	docker run -it --rm -v "$(shell pwd):/plugin:ro" buildkite/plugin-linter --id automattic/nvm
