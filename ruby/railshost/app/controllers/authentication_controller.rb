class AuthenticationController < ActionController::API
  def login
    response = {
      user: params[:user],
      token: Base64.urlsafe_encode64(params[:pass])
    }
    render json: response
  end
end
