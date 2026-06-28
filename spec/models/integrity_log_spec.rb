require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  describe "validations" do
    it 'requires key identifiers' do
      expect { IntegrityLog.new(idfa: nil).save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
