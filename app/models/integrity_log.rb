class IntegrityLog < ApplicationRecord
    validates :idfa, :ban_status, :ip, presence: true
end
