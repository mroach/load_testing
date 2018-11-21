get '/warmup', to: ->(env) { [200, {}, ['OK']] }
get '/alive', to: ->(env) { [200, {}, ['OK']] }
get '/platform', to: ->(env) { [200, {}, ["Hanami #{Hanami::Version.version}/Ruby #{RUBY_VERSION}"]] }
post '/login', to: 'benchmark#login'
