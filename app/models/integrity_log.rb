class IntegrityLog < ApplicationRecord
    validates :idfa, presence: true
end
