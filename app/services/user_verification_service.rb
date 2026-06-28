class UserVerificationService
    def initialize(idfa:, rooted_device:, ip:, country_header:)
      @idfa = idfa
      @rooted_device = ActiveModel::Type::Boolean.new.cast(rooted_device)
      @ip = ip
      @country_header = country_header
    end

    def call
      user = User.find_or_initialize_by(idfa: @idfa)

      # Rule: Short-circuit if already banned
      return user if user.persisted? && user.banned?

      previous_status = user.ban_status
      user.ban_status = evaluate_security_status

      if user.save && (user.previously_new_record? || previous_status != user.ban_status)
        trigger_log(user.ban_status)
      end

      user
    end

    private

    def evaluate_security_status
      return "banned" if @rooted_device == true
      # Add country_blacklisted? and vpn_or_tor_detected? stubs here
      "not_banned"
    end

    def trigger_log(status)
      IntegrityLoggerService.log!({
        idfa: @idfa, ban_status: status, ip: @ip, rooted_device: @rooted_device,
        country: @country_header, proxy: false, vpn: false
      })
    end
end
