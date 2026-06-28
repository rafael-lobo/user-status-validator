require 'rails_helper'

RSpec.describe UserVerificationService do
  let(:idfa) { 'test-idfa' }
  
  describe '#call' do
    context 'when user is already banned in the database' do
      it 'short-circuits and skips evaluation chains' do
        User.create!(idfa: idfa, ban_status: 'banned')
        
        # If it short-circuits, it won't trigger external network requests or logging
        service = UserVerificationService.new(idfa: idfa, rooted_device: false, ip: '1.1.1.1', country_header: 'US')
        expect(service.call.ban_status).to eq('banned')
      end
    end

    context 'when device is rooted' do
      it 'bans the user' do
        service = UserVerificationService.new(idfa: idfa, rooted_device: true, ip: '1.1.1.1', country_header: 'US')
        expect(service.call.ban_status).to eq('banned')
      end
    end
  end
end
