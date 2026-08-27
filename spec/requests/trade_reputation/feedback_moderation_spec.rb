# frozen_string_literal: true

describe "Trade Reputation feedback moderation", type: :request do
  fab!(:buyer) { Fabricate(:user) }
  fab!(:seller) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }

  before do
    SiteSetting.trade_reputation_enabled = true
    SiteSetting.hide_new_user_profiles = false
  end

  def feedback
    @feedback ||=
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 42,
        reviewer: buyer,
        reviewee: seller,
        rating: :positive,
        comment: "original feedback",
      )
  end

  it "allows staff to invalidate feedback while retaining its audit record" do
    sign_in(admin)

    put "/trade-reputation/feedbacks/#{feedback.id}/invalidate.json",
        params: { reason: "abusive content" }

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "success" => true })

    feedback.reload
    expect(feedback).to be_invalidated
    expect(feedback.moderated_by_id).to eq(admin.id)
    expect(feedback.moderated_at).to be_present
    expect(feedback.moderation_reason).to eq("abusive content")
    expect(feedback.comment).to eq("original feedback")
  end

  it "does not allow a regular user to invalidate feedback" do
    sign_in(buyer)

    put "/trade-reputation/feedbacks/#{feedback.id}/invalidate.json",
        params: { reason: "hide this" }

    expect(response.status).to eq(403)
    expect(feedback.reload).to be_active
  end

  it "removes invalidated feedback from public profile history and aggregates" do
    feedback.update!(
      moderation_status: :invalidated,
      moderated_at: Time.zone.now,
      moderated_by: admin,
      moderation_reason: "abusive content",
    )

    get "/trade-reputation/users/#{seller.username}/trade.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["summary"]["all_time"]["total"]).to eq(0)
    expect(response.parsed_body["feedbacks"]).to eq([])
  end

  it "keeps invalidated feedback as already reviewed for duplicate eligibility" do
    feedback.update!(
      moderation_status: :invalidated,
      moderated_at: Time.zone.now,
      moderated_by: admin,
      moderation_reason: "abusive content",
    )

    info =
      Marketplace::TradeContract::TransactionInfo.new(
        transaction_id: feedback.marketplace_transaction_id,
        buyer_id: buyer.id,
        seller_id: seller.id,
        completed_at: Time.current,
      )
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(feedback.marketplace_transaction_id)
      .and_return(info)

    sign_in(buyer)
    get "/trade-reputation/feedbacks/#{feedback.marketplace_transaction_id}/eligibility.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "eligible" => false, "already_reviewed" => true })
  end
end
