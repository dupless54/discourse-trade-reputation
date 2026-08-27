# frozen_string_literal: true

describe "Trade Reputation profile route" do
  fab!(:user) { Fabricate(:user) }

  before { SiteSetting.hide_new_user_profiles = false }

  it "serves the trade profile page on a direct request" do
    get "/u/#{user.username}/trade"

    expect(response.status).to eq(200)
  end
end
