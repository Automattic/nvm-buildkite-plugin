# Changelog

The format of this document is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- This is a comment, you won't see it when GitHub renders the Markdown file.

When releasing a new version:

1. Update the `## Unreleased` header to `## <version_number>`
2. Remove any empty section (those with `_None._`)
3. Add a new "Unreleased" section for the next iteration, by copy/pasting the following template:

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

-->

## Unreleased

### Breaking Changes

_None._

### New Features

_None._

### Bug Fixes

_None._

### Internal Changes

_None._

## 0.5.0

### Bug Fixes

* Fix issue with NVM directories not potentially being cleaned up after concurrently running build jobs [#20]

## 0.4.0

### Internal Changes

* Use "Node.js", the correct name for the platform, consistently in the logs [#18]
* Logs in `pre-command` hook show `:node:` emoji like those in `pre-exit` already did [#17]

## 0.3.0

### New Features

* Add a new option `curlrc` which allows pipelines to pass extra arguments to curl commands.

## 0.2.1

### Bug Fixes

* Fix issue in macOS when a script tried to `source` the `$NVM_DIR` [#9]

## 0.2.0

### Bug Fixes

* Fix issue where the plugin fails on macOS VMs.
* Fix issue where the plugin fails when no .nvmrc file and no node version specified.

## 0.1.0

### New Features

* Install node using nvm and update the running pipeline's process to use the installed node.
