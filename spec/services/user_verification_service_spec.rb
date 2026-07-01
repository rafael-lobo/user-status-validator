require 'rails_helper'

RSpec.describe UserVerificationService do
    let(:ip) { '8.8.8.8' }
    let(:idfa) { 'test-user' }
    let(:service) { described_class.new(idfa: idfa, rooted_device: false, ip: ip, country_header: 'US') }

    before do
      Rails.cache.clear
      Redis.new.sadd("whitelist:countries", "US")
    end

  describe '#call' do
    context 'when user is already banned in the database' do
      it 'short-circuits and skips evaluation chains' do
        User.create!(idfa: idfa, ban_status: 'banned')
        expect(service.call.ban_status).to eq('banned')
      end
    end

    context 'when device is rooted' do
      it 'bans the user' do
        bad_service = described_class.new(idfa: idfa, rooted_device: true, ip: ip, country_header: 'US')
        expect(bad_service.call.ban_status).to eq('banned')
      end
    end

    context 'when country is not whitelisted' do
        it 'bans the user' do
            Redis.new.del("whitelist:countries")
            expect(service.call.ban_status).to eq('banned')
        end
    end

    context 'when VPN is detected' do
        it 'caches responses for 24 hours and bans' do
            stub_request(:get, /vpnapi.io/).to_return(status: 200, body: { security: { vpn: true } }.to_json)

            expect(service.call.ban_status).to eq('banned')
            expect(Rails.cache.read("vpn_cache:#{ip}")).to eq(true)
        end

        it 'passes check if VPNAPI hits a rate limit (429) or crashes' do
            stub_request(:get, /vpnapi.io/).to_return(status: 429)
            expect(service.call.ban_status).to eq('not_banned')
          end
    end
  end
end
