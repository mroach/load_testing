FROM elixir:1.7-alpine

ENV MIX_ENV prod
ENV PORT 7000

EXPOSE 7000

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

ENTRYPOINT ["mix"]
CMD ["phx.server"]
