FROM crystallang/crystal:0.27.0

ENV AMBER_ENV production
ENV PORT 7000

EXPOSE 7000

RUN mkdir /app && \
    mkdir /app/bin

WORKDIR /app

COPY . /app
RUN shards install

RUN crystal build --no-debug --release --verbose -t -s -p -o bin/amberhost_prod src/amberhost.cr

CMD bin/amberhost_prod
