FROM ruby:2.5-alpine

ENV RACK_ENV production
ENV PORT 7000
ENV WORKERS 3

EXPOSE 7000

# build-base required to build native extensions
RUN apk add build-base

RUN mkdir /app && \
    mkdir /app/bin

WORKDIR /app

COPY . /app
RUN bundle install --without development test

CMD ["bundle", "exec", "puma", "-w3", "-p7000", "--preload"]
