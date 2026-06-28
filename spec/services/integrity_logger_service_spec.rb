require 'rails_helper'

RSpec.describe IntegrityLoggerService do
  describe '.log!' do
    let(:log_params) do
      { idfa: '123', ban_status: 'banned', ip: '1.1.1.1', rooted_device: false, country: 'US', proxy: false, vpn: false }
    end

    it 'creates an IntegrityLog record' do
      expect { IntegrityLoggerService.log!(log_params) }.to change(IntegrityLog, :count).by(1)
    end
  end
end
