require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  describe "validations" do
    it 'requires an idfa and ban_status' do
      log = IntegrityLog.new(ip: '1.1.1.1', rooted_device: false)
      expect(log.valid?).to be_falsey
    end
  end
end
