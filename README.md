# Load testing with K6

This project aims to compare the load capacity of different web frameworks and languages.

Frameworks available for testing:

* Rails 5.2 (Ruby)
* Hanami (Ruby)
* Amber (Crystal)
* Phoenix (Elixir)

## Pre-requisites

To run the full benchmarking suite, you'll need the following installed:

* Ruby 2.5.x
* Crystal
* Elixir
* nginx

## Running the benchmarks

If you're running everything on your local system, you don't have much to do.

See the `README` files in each app's directory to see about installing dependencies.

Then, just run:

```shell
./bench.rb
```

The results will be in the `results/` dir in JSON format.
