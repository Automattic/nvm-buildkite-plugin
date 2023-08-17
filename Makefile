validate:
	docker run -it --rm -v "$(shell pwd):/plugin:ro" buildkite/plugin-linter --id automattic/nvm
