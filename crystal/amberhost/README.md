# amberhost

[![Amber Framework](https://img.shields.io/badge/using-amber_framework-orange.svg)](https://amberframework.org)

This is a project written using [Amber](https://amberframework.org).

## Prerequisites

This project requires [Crystal](https://crystal-lang.org/) ([installation guide](https://crystal-lang.org/docs/installation/)).

## Development

To start your Amber server:

1. Install dependencies with `shards install`
2. Build executables with `shards build`
3. Start Amber development server with `bin/amber watch`

Now you can visit http://localhost:3000/ from your browser.

## Production

As of this writing, the best way to run Amber in production is to compile it down
to a binary and then run it.

*Compile*:

```shell
crystal build --no-debug --release --verbose -t -s -p -o bin/amberhost_prod src/amberhost.cr
```

*Run*:

```shell
AMBER_ENV=production PORT=7000 bin/amberhost_prod
```
