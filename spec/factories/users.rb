FactoryBot.define do
  factory :user do
    idfa { "test-idfa" }
    ban_status { "not_banned" }
  end
end
