require 'rails_helper'

RSpec.describe "V1::User::Statuses", type: :request do
  before do
    Redis.new.sadd("whitelist:countries", "US")
    stub_request(:get, /vpnapi.io/).to_return(status: 200, body: { security: { vpn: false } }.to_json)
  end

  it "returns the correct JSON format" do
    headers = { "CONTENT_TYPE" => "application/json", "HTTP_CF_IPCOUNTRY" => "US" }
    params = { idfa: "test-idfa", rooted_device: false }

    post "/v1/user/check_status", params: params.to_json, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq({ "ban_status" => "not_banned" })
  end
end
