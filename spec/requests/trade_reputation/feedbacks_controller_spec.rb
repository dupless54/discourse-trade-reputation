# frozen_string_literal: true

describe TradeReputation::FeedbacksController do
  fab!(:buyer, :user)
  fab!(:seller, :user)
  fab!(:other_user, :user)

  before do
    SiteSetting.trade_reputation_enabled = true
  end

  def stub_transaction_info(transaction_id: 1, **overrides)
    info =
      Marketplace::TradeContract::TransactionInfo.new(
        transaction_id: transaction_id,
        buyer_id: buyer.id,
        seller_id: seller.id,
        completed_at: Time.current,
        **overrides,
      )
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(transaction_id)
      .and_return(info)
    info
  end

  def eligibility_path(id)
    "/trade-reputation/feedbacks/#{id}/eligibility.json"
  end

  describe "routing / input" do
    it "resolves a positive integer id to the eligibility action" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.status).to eq(200)
    end

    it "returns 404 for a zero id" do
      sign_in(buyer)

      get eligibility_path(0)

      expect(response.status).to eq(404)
    end

    it "returns 404 for a negative id" do
      sign_in(buyer)

      get "/trade-reputation/feedbacks/-1/eligibility.json"

      expect(response.status).to eq(404)
    end

    it "returns 404 for a non-integer id" do
      sign_in(buyer)

      get "/trade-reputation/feedbacks/abc/eligibility.json"

      expect(response.status).to eq(404)
    end

    it "returns 404 for a trailing non-digit id like 123abc" do
      sign_in(buyer)

      get "/trade-reputation/feedbacks/123abc/eligibility.json"

      expect(response.status).to eq(404)
    end

    it "returns 404 for a leading-zero id like 007" do
      sign_in(buyer)

      get "/trade-reputation/feedbacks/007/eligibility.json"

      expect(response.status).to eq(404)
    end
  end

  describe "auth" do
    it "rejects an anonymous request" do
      get eligibility_path(1)

      expect(response.status).to eq(403)
    end
  end

  describe "eligible" do
    it "allows the buyer of a completed transaction" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => true })
    end

    it "allows the seller of a completed transaction" do
      sign_in(seller)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => true })
    end

    it "allows a historical completed transaction with no event delivery involved" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1, completed_at: 2.years.ago)

      get eligibility_path(1)

      expect(response.parsed_body["eligible"]).to eq(true)
    end
  end

  describe "privacy / ineligible" do
    it "returns eligible false for an unknown transaction" do
      sign_in(buyer)
      allow(Marketplace::TradeContract).to receive(:completed_transaction_info).with(1).and_return(nil)

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => false })
    end

    it "returns the identical response for a non-completed transaction" do
      sign_in(buyer)
      allow(Marketplace::TradeContract).to receive(:completed_transaction_info).with(1).and_return(nil)

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => false })
    end

    it "returns the identical response for an authenticated non-participant" do
      sign_in(other_user)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => false })
    end

    it "never exposes participant or transaction fields in an ineligible response" do
      sign_in(other_user)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.body).not_to match(/buyer_id|seller_id|reviewee_id|completed_at|Marketplace|TradeContract|VERSION/)
    end
  end

  describe "duplicate" do
    it "reports already_reviewed for a participant who already left feedback" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 1,
        reviewer_id: buyer.id,
        reviewee_id: seller.id,
        rating: :positive,
      )

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => false, "already_reviewed" => true })
    end

    it "does not make the current participant ineligible because the other participant already reviewed" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 1,
        reviewer_id: seller.id,
        reviewee_id: buyer.id,
        rating: :positive,
      )

      get eligibility_path(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to eq({ "eligible" => true })
    end
  end

  describe "marketplace contract availability" do
    it "returns 503 with the standard error shape when TradeContract is undefined" do
      sign_in(buyer)
      hide_const("Marketplace::TradeContract")

      get eligibility_path(1)

      expect(response.status).to eq(503)
      expect(response.parsed_body["errors"]).to eq(
        [I18n.t("trade_reputation.errors.temporarily_unavailable")],
      )
    end

    it "returns 503 without raising when VERSION is undefined" do
      sign_in(buyer)
      hide_const("Marketplace::TradeContract::VERSION")

      expect { get eligibility_path(1) }.not_to raise_error

      expect(response.status).to eq(503)
    end

    it "returns 503 when VERSION is unsupported" do
      sign_in(buyer)

      stub_const(Marketplace::TradeContract, :VERSION, 2) do
        get eligibility_path(1)

        expect(response.status).to eq(503)
      end
    end

    it "proceeds normally when VERSION == 1" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.status).to eq(200)
    end

    it "does not leak internal details in the 503 body" do
      sign_in(buyer)
      hide_const("Marketplace::TradeContract")

      get eligibility_path(1)

      expect(response.body).not_to match(/Marketplace|TradeContract|VERSION/)
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "response shape" do
    it "an eligible response contains only the eligible key" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.parsed_body.keys).to contain_exactly("eligible")
    end

    it "an ordinary ineligible response contains only the eligible key" do
      sign_in(other_user)
      stub_transaction_info(transaction_id: 1)

      get eligibility_path(1)

      expect(response.parsed_body.keys).to contain_exactly("eligible")
    end

    it "an already-reviewed response contains only eligible and already_reviewed" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 1,
        reviewer_id: buyer.id,
        reviewee_id: seller.id,
        rating: :positive,
      )

      get eligibility_path(1)

      expect(response.parsed_body.keys).to contain_exactly("eligible", "already_reviewed")
    end
  end

  describe "#create" do
    let(:create_path) { "/trade-reputation/feedbacks.json" }

    def post_feedback(params)
      post create_path, params: params
    end

    it "rejects an anonymous request" do
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.status).to eq(403)
    end

    it "allows the buyer to leave feedback for the seller" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "positive", comment: "great trade")

      expect(response.status).to eq(201)
      expect(response.parsed_body).to eq({ "success" => true })

      feedback = TradeReputation::Feedback.last
      expect(feedback.reviewer_id).to eq(buyer.id)
      expect(feedback.reviewee_id).to eq(seller.id)
      expect(feedback.rating).to eq("positive")
      expect(feedback.comment).to eq("great trade")
    end

    it "allows the seller to leave feedback for the buyer" do
      sign_in(seller)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "negative")

      expect(response.status).to eq(201)
      expect(response.parsed_body).to eq({ "success" => true })

      feedback = TradeReputation::Feedback.last
      expect(feedback.reviewer_id).to eq(seller.id)
      expect(feedback.reviewee_id).to eq(buyer.id)
      expect(feedback.rating).to eq("negative")
    end

    it "derives the reviewee from the transaction and ignores client-supplied identities" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      post_feedback(
        marketplace_transaction_id: 1,
        rating: "positive",
        reviewer_id: other_user.id,
        reviewee_id: other_user.id,
        buyer_id: other_user.id,
        seller_id: other_user.id,
      )

      expect(response.status).to eq(201)
      feedback = TradeReputation::Feedback.last
      expect(feedback.reviewer_id).to eq(buyer.id)
      expect(feedback.reviewee_id).to eq(seller.id)
    end

    it "returns 422 for an invalid marketplace_transaction_id" do
      sign_in(buyer)

      post_feedback(marketplace_transaction_id: 0, rating: "positive")

      expect(response.status).to eq(422)
    end

    it "returns 422 for an invalid rating" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "amazing")

      expect(response.status).to eq(422)
    end

    it "returns 422 for an unknown transaction" do
      sign_in(buyer)
      allow(Marketplace::TradeContract).to receive(:completed_transaction_info).with(1).and_return(nil)

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.status).to eq(422)
    end

    it "returns 422 for an authenticated non-participant" do
      sign_in(other_user)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.status).to eq(422)
    end

    it "returns 409 for a duplicate submission" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 1,
        reviewer_id: buyer.id,
        reviewee_id: seller.id,
        rating: :positive,
      )

      post_feedback(marketplace_transaction_id: 1, rating: "negative")

      expect(response.status).to eq(409)
      expect(TradeReputation::Feedback.where(marketplace_transaction_id: 1).count).to eq(1)
    end

    it "returns 503 when Marketplace::TradeContract is undefined" do
      sign_in(buyer)
      hide_const("Marketplace::TradeContract")

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.status).to eq(503)
      expect(response.parsed_body["errors"]).to eq(
        [I18n.t("trade_reputation.errors.temporarily_unavailable")],
      )
    end

    it "returns 503 when Marketplace::TradeContract::VERSION is unsupported" do
      sign_in(buyer)

      stub_const(Marketplace::TradeContract, :VERSION, 2) do
        post_feedback(marketplace_transaction_id: 1, rating: "positive")

        expect(response.status).to eq(503)
      end
    end

    it "returns only the success key on success" do
      sign_in(buyer)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.parsed_body.keys).to contain_exactly("success")
    end

    it "does not leak private/internal identifiers in error responses" do
      sign_in(other_user)
      stub_transaction_info(transaction_id: 1)

      post_feedback(marketplace_transaction_id: 1, rating: "positive")

      expect(response.body).not_to match(
        /buyer_id|seller_id|reviewee_id|reviewer_id|completed_at|Marketplace|TradeContract|VERSION/,
      )
    end
  end
end
