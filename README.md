# Node Buildkite Plugin

Set up node.js environment using [nvm](https://github.com/nvm-sh/nvm).

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - automattic/nvm#0.2.0:
          version: 'v18'
```

## Configuration

### `version` (Optional, string)

The node.js version [that nvm supports](https://github.com/nvm-sh/nvm#nvmrc). If it's not set, the project's `.nvmrc` file will be used.

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request
