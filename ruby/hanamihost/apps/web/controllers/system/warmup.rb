module Web
  module Controllers
    module System
      class Warmup
        include Web::Action

        def call(params)
          self.format = :json
          self.body = { status: :running }.to_json
        end
      end
    end
  end
end
