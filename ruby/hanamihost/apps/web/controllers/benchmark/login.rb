module Web
  module Controllers
    module Benchmark
      class Login
        include Web::Action

        params do
          required(:user).filled(:str?)
          required(:pass).filled(:str?)
        end

        def call(params)
          require 'base64'
          self.format = :json
          halt 400 unless params.valid?
          response = {
            user: params[:user],
            token: ::Base64.urlsafe_encode64(params[:pass])
          }
          self.body = response.to_json
        end
      end
    end
  end
end
