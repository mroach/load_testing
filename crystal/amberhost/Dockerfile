FROM amberframework/amber:v0.11.1

WORKDIR /app

COPY shard.* /app/
RUN shards install

COPY . /app

CMD amber watch
