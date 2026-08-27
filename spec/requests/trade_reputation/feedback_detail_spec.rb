# frozen_string_literal: true

describe "Trade Reputation feedback detail", type: :request do
  fab!(:buyer) { Fabricate(:user) }
  fab!(:seller) { Fabricate(:user) }

  before do
    SiteSetting.trade_reputation_enabled = true
    SiteSetting.hide_new_user_profiles = false
  end

  def feedback
    @feedback ||=
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 77,
        reviewer: buyer,
        reviewee: seller,
        rating: :positive,
        comment: "verified trade",
      )
  end

  def transaction_info
    Data.define(:transaction_id, :listing_id, :buyer_id, :seller_id, :completed_at).new(
      transaction_id: feedback.marketplace_transaction_id,
      listing_id: 1234,
      buyer_id: buyer.id,
      seller_id: seller.id,
      completed_at: Time.zone.local(2026, 8, 27, 12, 0, 0),
    )
  end

  def detail_path
    "/trade-reputation/feedbacks/public/#{feedback.public_id}.json"
  end

  it "returns public detail derived from a freshly verified completed transaction" do
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(feedback.marketplace_transaction_id)
      .and_return(transaction_info)

    get detail_path

    expect(response.status).to eq(200)
    body = response.parsed_body.fetch("feedback")
    expect(body["public_id"]).to eq(feedback.public_id)
    expect(body["transaction_reference"]).to eq("TR-77")
    expect(body["listing_reference"]).to eq("LISTING-1234")
    expect(body["buyer"]["username"]).to eq(buyer.username)
    expect(body["seller"]["username"]).to eq(seller.username)
    expect(body["rating"]).to eq("positive")
    expect(body["comment"]).to eq("verified trade")
    expect(body["completed_at"]).to be_present
  end

  it "does not expose internal linkage or database ids" do
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .and_return(transaction_info)

    get detail_path

    %w[marketplace_transaction_id buyer_id seller_id listing_id reviewer_id reviewee_id moderated_by_id].each do |field|
      expect(response.body).not_to include(field)
    end
    expect(response.parsed_body.fetch("feedback")).not_to have_key("id")
  end

  it "returns 404 when the reviewed user's profile is hidden" do
    seller.user_option.update!(hide_profile: true)
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .and_return(transaction_info)

    get detail_path

    expect(response.status).to eq(404)
  end

  it "returns 404 when the feedback has been invalidated" do
    admin = Fabricate(:admin)
    feedback.update!(
      moderation_status: :invalidated,
      moderated_at: Time.zone.now,
      moderated_by: admin,
      moderation_reason: "abusive content",
    )

    get detail_path

    expect(response.status).to eq(404)
  end

  it "returns 404 when Marketplace no longer verifies the completed transaction" do
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(feedback.marketplace_transaction_id)
      .and_return(nil)

    get detail_path

    expect(response.status).to eq(404)
  end

  it "returns 503 when the Marketplace public contract is unavailable" do
    hide_const("Marketplace::TradeContract")

    get detail_path

    expect(response.status).to eq(503)
  end

  it "returns 503 when the Marketplace contract does not expose a listing reference" do
    legacy_info =
      Marketplace::TradeContract::TransactionInfo.new(
        transaction_id: feedback.marketplace_transaction_id,
        buyer_id: buyer.id,
        seller_id: seller.id,
        completed_at: Time.zone.local(2026, 8, 27, 12, 0, 0),
      )

    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(feedback.marketplace_transaction_id)
      .and_return(legacy_info)

    get detail_path

    expect(response.status).to eq(503)
  end
end
