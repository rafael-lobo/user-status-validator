require "net/http"
require "json"

class UserVerificationService
  def initialize(idfa:, rooted_device:, ip:, country_header:)
    @idfa = idfa
    @rooted_device = ActiveModel::Type::Boolean.new.cast(rooted_device)
    @ip = ip
    @country_header = country_header
  end

  def call
    user = User.find_or_initialize_by(idfa: @idfa)

    return user if user.persisted? && user.banned? # Skip checks if already banned

    previous_status = user.ban_status
    user.ban_status = evaluate_security_status

    if user.save && (user.previously_new_record? || previous_status != user.ban_status) # Log ONLY on creation or status change
      trigger_log(user.ban_status)
    end

    user
  end

  private

  def evaluate_security_status
    return "banned" if @rooted_device == true
    return "banned" if country_blacklisted?
    return "banned" if vpn_or_tor_detected?
    "not_banned"
  end

  def country_blacklisted?
    return true if @country_header.blank?
    !Redis.new.sismember("whitelist:countries", @country_header)
  end

  def vpn_or_tor_detected?
    # Checks Redis first, if missing -> runs the block and saves for 24h
    Rails.cache.fetch("vpn_cache:#{@ip}", expires_in: 24.hours) do
      begin
        uri = URI("https://vpnapi.io/api/#{@ip}?key=#{ENV['VPNAPI_KEY']}")
        response = Net::HTTP.get_response(uri)

        # If rate limited/error -> return false to pass the check safely
        return false unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        data.dig("security", "vpn") || data.dig("security", "tor")
      rescue StandardError
        false # Failsafe for network timeouts
      end
    end
  end

  def trigger_log(status)
    IntegrityLoggerService.log!(
      idfa: @idfa, ban_status: status, ip: @ip, rooted_device: @rooted_device,
      country: @country_header, proxy: nil, vpn: nil
    )
  end
end
