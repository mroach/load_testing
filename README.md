# Load testing with K6

This project aims to compare the load capacity of different web frameworks and languages.

Frameworks available for testing:

* Rails 5.2
* Hanami (Ruby)
* Amber (Crystal)
* Phoenix (Elixir)

## Setup

To run the benchmarks, you need [k6](https://k6.io) setup on your system.

```shell
brew tap loadimpact/k6
brew install k6
```

### nginx

To establish a baseline/control benchmark, you can install nginx and use
the config file in the `nginx/` dir as a server. It returns a string directly
from server configuration so it's as fast as an HTTP server could be.

### App setup

Each app has its own `README` file to explain how to get it running.

## Running the benchmarks

The strategy is that each app runs on a different port, so when you run the benchmark
you simply set the `PORT` environment variable to connect to the right app.

> TODO: Orchestrate a more clean way of doing this. Start commands and ports
> could come from a config file and then make a small command like:
> `./bench.sh phoenix

Here's an example of how you'd start all the apps. Each in their own tmux window
for example:

```shell
cd ruby/hanamihost; bundle exec puma -p 2301 -e production -w 4
cd ruby/railshost; bundle exec puma -p 3001 -e production -w 4
cd crystal/amberhost; AMBER_ENV=production PORT=5000 amber watch
cd elixir/phoenixhost; env MIX_ENV=prod PORT=4000 phx.server
```

Then benchmark each one:

```shell
# benchmark phoenix
k6 run -e PORT=4000 bench.js
```
