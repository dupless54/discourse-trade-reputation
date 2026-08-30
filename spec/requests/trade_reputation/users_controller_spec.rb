# frozen_string_literal: true

describe TradeReputation::UsersController do
  fab!(:target_user, :user)
  fab!(:reviewer, :user)

  before do
    SiteSetting.trade_reputation_enabled = true
    SiteSetting.hide_new_user_profiles = false
  end

  def trade_path(username)
    "/trade-reputation/users/#{username}/trade.json"
  end

  describe "visible profile" do
    it "returns 200 and the real query result end-to-end" do
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 1,
        reviewer_id: reviewer.id,
        reviewee_id: target_user.id,
        rating: :positive,
        comment: "great trade",
      )

      get trade_path(target_user.username)

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["summary"]["all_time"]["total"]).to eq(1)
      expect(body["feedbacks"].size).to eq(1)
    end

    it "allows an anonymous visitor to view an ordinary public profile" do
      get trade_path(target_user.username)
      expect(response.status).to eq(200)
    end
  end

  describe "unknown username" do
    it "returns 404 for a nonexistent username" do
      get trade_path("does-not-exist-#{SecureRandom.hex(4)}")
      expect(response.status).to eq(404)
    end
  end

  describe "hidden profile" do
    it "returns 404 when the target user has hidden their profile" do
      target_user.user_option.update!(hide_profile: true)
      get trade_path(target_user.username)
      expect(response.status).to eq(404)
    end
  end

  describe "response shape" do
    it "exposes exactly summary, feedbacks, meta at the top level" do
      get trade_path(target_user.username)
      expect(response.parsed_body.keys).to contain_exactly("summary", "feedbacks", "meta")
    end

    it "exposes exactly the approved feedback and reviewer fields" do
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 2,
        reviewer_id: reviewer.id,
        reviewee_id: target_user.id,
        rating: :positive,
        comment: "nice",
      )

      get trade_path(target_user.username)
      entry = response.parsed_body["feedbacks"].first

      expect(entry.keys).to contain_exactly(
        "public_id",
        "transaction_reference",
        "rating",
        "comment",
        "created_at",
        "reviewer",
      )
      expect(entry["reviewer"].keys).to contain_exactly("username", "avatar_template")
    end
  end

  describe "privacy" do
    it "never exposes internal linkage or database ids" do
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 3,
        reviewer_id: reviewer.id,
        reviewee_id: target_user.id,
        rating: :positive,
        comment: "thanks",
      )

      get trade_path(target_user.username)

      %w[marketplace_transaction_id buyer_id seller_id listing_id reviewer_id reviewee_id].each do |field|
        expect(response.body).not_to include(field)
      end

      entry = response.parsed_body["feedbacks"].first
      expect(entry).not_to have_key("id")
      expect(entry["public_id"]).to match(/\A[0-9a-f-]{36}\z/)
      expect(entry["transaction_reference"]).to eq("TR-3")
      expect(entry["reviewer"]).not_to have_key("id")
    end

    it "does not expose a reviewer whose profile is hidden from the viewer" do
      reviewer.user_option.update!(hide_profile: true)
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: 4,
        reviewer_id: reviewer.id,
        reviewee_id: target_user.id,
        rating: :positive,
      )

      get trade_path(target_user.username)

      entry = response.parsed_body["feedbacks"].first
      expect(entry["reviewer"]).to be_nil
      expect(response.body).not_to include(reviewer.username)
    end
  end

  describe "pagination integration" do
    it "applies page/per_page from request params" do
      3.times do |i|
        TradeReputation::Feedback.create!(
          marketplace_transaction_id: 100 + i,
          reviewer_id: reviewer.id,
          reviewee_id: target_user.id,
          rating: :positive,
        )
      end

      get "#{trade_path(target_user.username)}?per_page=1&page=2"
      body = response.parsed_body
      expect(body["meta"]["page"]).to eq(2)
      expect(body["meta"]["per_page"]).to eq(1)
      expect(body["feedbacks"].size).to eq(1)
    end

    it "returns 400 for an invalid pagination param" do
      get "#{trade_path(target_user.username)}?page=abc"
      expect(response.status).to eq(400)
    end
  end

  describe "plugin disabled" do
    it "returns 404 when the plugin is disabled" do
      SiteSetting.trade_reputation_enabled = false
      get trade_path(target_user.username)
      expect(response.status).to eq(404)
    end
  end
end
