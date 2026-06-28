require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { User.new(idfa: "test-idfa", ban_status: "not_banned") }
    it { is_expected.to validate_presence_of(:idfa) }
    it { is_expected.to validate_uniqueness_of(:idfa) }
    it { is_expected.to validate_presence_of(:ban_status) }
  end

  describe "enum flexibility" do
    it "supports banned status" do
      expect{ User.new(idfa: "test-idfa", ban_status: "banned").save! }.not_to raise_error
    end

    it "supports not_banned status" do
      expect{ User.new(idfa: "test-idfa", ban_status: "not_banned").save! }.not_to raise_error
    end 

    it "defaults to not_banned status" do
      user = User.new(idfa: "test-idfa")
      expect(user.ban_status).to eq("not_banned")
    end
  end
end
