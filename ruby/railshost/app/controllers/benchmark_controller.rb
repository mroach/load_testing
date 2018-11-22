class BenchmarkController < ApplicationController
  def warmup
    render plain: "OK"
  end

  def alive
    render plain: "OK"
  end

  def platform
    render plain: "Rails #{Rails.version}/Ruby #{RUBY_VERSION} (#{Rails.env})"
  end

  def login
    response = {
      user: params[:user],
      token: Base64.urlsafe_encode64(params[:pass])
    }
    render json: response
  end
end
