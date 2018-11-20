class AuthenticationController < ApplicationController
  def login
    context.response.content_type = "application/json"
    data = { user: params[:user], token: Base64.urlsafe_encode(params[:pass]) }
    data.to_json
  end
end
