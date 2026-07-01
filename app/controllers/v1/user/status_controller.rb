class V1::User::StatusController < ApplicationController
  def check
    user = UserVerificationService.new(
      idfa: params[:idfa],
      rooted_device: params[:rooted_device],
      ip: request.remote_ip,
      country_header: request.headers["CF-IPCountry"]
    ).call

    render json: { ban_status: user.ban_status }, status: :ok
  end
end
