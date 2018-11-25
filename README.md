# Load testing with K6

This project aims to compare the load capacity of different web frameworks and languages.

Frameworks available for testing:

* Rails 5.2 (Ruby)
* Hanami (Ruby)
* Amber (Crystal)
* Phoenix (Elixir)

## Pre-requisites

The easiest way to get running is to uad the provided Docker configuration.
This spares you from having to manually install Ruby, Crystal, Elixir, nginx,
and other stuff.

### Docker

With Docker installed and running, start the host servers with:

```shell
docker-compose up
```

Now you can hit `localhost:8080` to get to the apps. Controlling which app is hit
is done via the HTTP `Host` header. For example:

```shell
curl -H "Host: phoenix" localhost:8080/platform
```

### Without docker

To run the full benchmarking suite, you'll need the following installed:

* Ruby 2.5.x
* Crystal
* Elixir
* nginx

Then see the `README` files in each app's directory to see about installing dependencies.

## Running the benchmarks

> TODO: Make bench.rb smart and use the Docker host or manually starting servers

Then, just run:

```shell
./bench.rb
```

The results will be in the `results/` dir in JSON format.
