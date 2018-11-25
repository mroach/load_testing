FROM ruby:2.5-alpine

ENV RACK_ENV production
ENV RAILS_ENV production
ENV PORT 7000
ENV WORKERS 3

EXPOSE 7000

# build-base required to build native extensions
# tzdata required by active support
RUN apk add build-base tzdata

RUN mkdir /app

WORKDIR /app
RUN mkdir bin log tmp

COPY . /app
RUN bundle install --without development test

CMD ["bundle", "exec", "puma", "-w3", "-p7000", "--preload"]
