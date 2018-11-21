class BenchmarkController < ApplicationController
  def warmup
    "OK"
  end

  def alive
    "OK"
  end

  def platform
    "Amber #{Amber::VERSION}/Crystal #{Crystal::VERSION}"
  end

  def login
    context.response.content_type = "application/json"
    data = { user: params[:user], token: Base64.urlsafe_encode(params[:pass]) }
    data.to_json
  end
end
