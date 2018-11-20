class SystemController < ApplicationController
  def warmup
    render json: { status: :running }
  end

  def alive
    render plain: "OK"
  end
end
