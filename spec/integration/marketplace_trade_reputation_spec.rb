# frozen_string_literal: true

# Cross-plugin integration coverage: exercises Trade Reputation against the
# real Marketplace::TradeContract and real Marketplace records, with both
# plugins loaded together (see about.json requiredPlugins). This spec must
# never stub/mock Marketplace::TradeContract — see docs/MARKETPLACE_CONTRACT.md
# for the boundary this guards against drifting.
describe "Marketplace <-> Trade Reputation integration", type: :request do
  fab!(:buyer) { Fabricate(:user) }
  fab!(:seller) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  fab!(:category) do
    Marketplace::Category.create!(
      name: "Integration Category",
      slug: "integration-category",
      position: 0,
      enabled: true,
    )
  end

  fab!(:listing) do
    Marketplace::Listing.create!(
      seller: seller,
      category: category,
      title: "Integration Listing",
      raw: "Integration listing description.",
      cooked: "<p>Integration listing description.</p>",
      price_cents: 1000,
      currency: "USD",
      status: Marketplace::Listing.statuses[:active],
    )
  end

  before { SiteSetting.trade_reputation_enabled = true }

  def build_pending
    Marketplace::Transaction.create!(
      listing: listing,
      buyer: buyer,
      seller: seller,
      status: Marketplace::Transaction.statuses[:pending],
    )
  end

  def build_completed
    transaction = build_pending
    now = Time.zone.now
    transaction.update_columns(
      status: Marketplace::Transaction.statuses[:completed],
      buyer_confirmed_at: now,
      seller_confirmed_at: now,
      completed_at: now,
    )
    transaction.reload
  end

  def build_cancelled
    transaction = build_pending
    transaction.update_columns(
      status: Marketplace::Transaction.statuses[:cancelled],
      cancelled_at: Time.zone.now,
      cancelled_by_id: seller.id,
    )
    transaction.reload
  end

  def eligibility_path(id)
    "/trade-reputation/feedbacks/#{id}/eligibility.json"
  end

  it "reports a real completed transaction as eligible for its buyer" do
    transaction = build_completed
    sign_in(buyer)

    get eligibility_path(transaction.id)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "eligible" => true })
  end

  it "creates real feedback for a real completed transaction, buyer -> seller" do
    transaction = build_completed
    sign_in(buyer)

    post "/trade-reputation/feedbacks.json",
         params: {
           marketplace_transaction_id: transaction.id,
           rating: "positive",
           comment: "real integration trade",
         }

    expect(response.status).to eq(201)
    expect(response.parsed_body).to eq({ "success" => true })

    feedbacks =
      TradeReputation::Feedback.where(marketplace_transaction_id: transaction.id)

    expect(feedbacks.count).to eq(1)

    feedback = feedbacks.first
    expect(feedback.reviewer_id).to eq(buyer.id)
    expect(feedback.reviewee_id).to eq(seller.id)
  end

  it "creates real feedback for a real completed transaction, seller -> buyer" do
    transaction = build_completed
    sign_in(seller)

    post "/trade-reputation/feedbacks.json",
         params: { marketplace_transaction_id: transaction.id, rating: "negative" }

    expect(response.status).to eq(201)

    feedback = TradeReputation::Feedback.find_by(marketplace_transaction_id: transaction.id)
    expect(feedback.reviewer_id).to eq(seller.id)
    expect(feedback.reviewee_id).to eq(buyer.id)
  end

  it "reports a real pending transaction as ineligible" do
    transaction = build_pending
    sign_in(buyer)

    get eligibility_path(transaction.id)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "eligible" => false })
  end

  it "reports a real cancelled transaction as ineligible" do
    transaction = build_cancelled
    sign_in(buyer)

    get eligibility_path(transaction.id)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "eligible" => false })
  end

  it "reports a real completed transaction as ineligible for an unrelated authenticated user, without leaking identifiers" do
    transaction = build_completed
    sign_in(other_user)

    get eligibility_path(transaction.id)

    expect(response.status).to eq(200)
    expect(response.parsed_body).to eq({ "eligible" => false })
    expect(response.body).not_to match(
      /buyer_id|seller_id|reviewer_id|reviewee_id|completed_at|Marketplace|TradeContract|VERSION/,
    )
  end

  it "rejects a duplicate submission against the same real transaction, leaving exactly one feedback row" do
    transaction = build_completed
    sign_in(buyer)

    post "/trade-reputation/feedbacks.json",
         params: { marketplace_transaction_id: transaction.id, rating: "positive" }
    expect(response.status).to eq(201)

    post "/trade-reputation/feedbacks.json",
         params: { marketplace_transaction_id: transaction.id, rating: "negative" }
    expect(response.status).to eq(409)

    expect(
      TradeReputation::Feedback.where(
        marketplace_transaction_id: transaction.id,
        reviewer_id: buyer.id,
      ).count,
    ).to eq(1)
  end
end
