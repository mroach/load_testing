# Configure your routes here
# See: http://hanamirb.org/guides/routing/overview/
#
# Example:
# get '/hello', to: ->(env) { [200, {}, ['Hello from Hanami!']] }
get '/warmup', to: 'system#warmup'
post '/login', to: 'authentication#login'
get '/alive', to: 'system#alive'
