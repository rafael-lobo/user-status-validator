FactoryBot.define do
  factory :integrity_log do
    idfa { "test-idfa" }
    ban_status { "not_banned" }
    ip { "127.0.0.1" }
    rooted_device { false }
    country { "US" }
    proxy { false }
    vpn { false }
  end
end
