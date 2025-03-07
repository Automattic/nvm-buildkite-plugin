# Node Buildkite Plugin

Set up Node.js environment using [nvm](https://github.com/nvm-sh/nvm).

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - command: ls
    plugins:
      - automattic/nvm#0.6.0:
          version: 'v18'
```

## Configuration

### `version` (Optional, string)

The Node.js version [that nvm supports](https://github.com/nvm-sh/nvm#nvmrc). If it's not set, the project's `.nvmrc` file will be used.

### `curlrc` (Optional, string)

Content of [a `.curlrc` file](https://curl.se/docs/manpage.html#-K). This option can be used to pass extra command line arguments to _all curl commands_. For example `--http1.1` makes nvm–which invokes curl commands—use HTTP1.1 protocol.

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request
