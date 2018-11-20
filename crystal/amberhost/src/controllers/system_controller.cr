class SystemController < ApplicationController
  def warmup
    context.response.content_type = "application/json"
    data = { status: "running" }
    data.to_json
  end
end
