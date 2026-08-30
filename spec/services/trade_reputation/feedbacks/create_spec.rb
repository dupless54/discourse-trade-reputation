# frozen_string_literal: true

describe TradeReputation::Feedbacks::Create do
  fab!(:buyer, :user)
  fab!(:seller, :user)
  fab!(:other_user, :user)

  let(:marketplace_transaction_id) { 1 }

  def stub_transaction_info(**overrides)
    info =
      Marketplace::TradeContract::TransactionInfo.new(
        transaction_id: marketplace_transaction_id,
        buyer_id: buyer.id,
        seller_id: seller.id,
        completed_at: Time.current,
        **overrides,
      )
    allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(marketplace_transaction_id)
      .and_return(info)
    info
  end

  def call_service(guardian:, rating: "positive", comment: nil, transaction_id: marketplace_transaction_id)
    described_class.call(
      guardian: guardian,
      params: {
        marketplace_transaction_id: transaction_id,
        rating: rating,
        comment: comment,
      },
    )
  end

  describe "success" do
    it "allows buyer to review seller, reviewer_id from guardian.user, reviewee_id derived server-side" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_success
      expect(result.feedback.reviewer_id).to eq(buyer.id)
      expect(result.feedback.reviewee_id).to eq(seller.id)
    end

    it "allows seller to review buyer, reviewer_id from guardian.user, reviewee_id derived server-side" do
      stub_transaction_info
      result = call_service(guardian: seller.guardian)

      expect(result).to be_success
      expect(result.feedback.reviewer_id).to eq(seller.id)
      expect(result.feedback.reviewee_id).to eq(buyer.id)
    end

    it "persists a positive rating" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian, rating: "positive")

      expect(result.feedback.rating).to eq("positive")
    end

    it "persists a neutral rating" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian, rating: "neutral")

      expect(result.feedback.rating).to eq("neutral")
    end

    it "persists a negative rating" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian, rating: "negative")

      expect(result.feedback.rating).to eq("negative")
    end

    it "accepts a nil comment" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian, comment: nil)

      expect(result).to be_success
      expect(result.feedback.comment).to be_nil
    end

    it "succeeds for a historical completed transaction with no event ever fired" do
      stub_transaction_info(completed_at: 2.years.ago)
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_success
    end
  end

  describe "input trust boundary" do
    it "does not declare reviewer_id or reviewee_id as accepted params attributes" do
      expect(described_class::Contract.attribute_names).to contain_exactly(
        "marketplace_transaction_id",
        "rating",
        "comment",
      )
    end

    it "ignores an injected reviewer_id/reviewee_id and derives them server-side regardless" do
      stub_transaction_info
      result =
        described_class.call(
          guardian: buyer.guardian,
          params: {
            marketplace_transaction_id: marketplace_transaction_id,
            rating: "positive",
            comment: nil,
            reviewer_id: other_user.id,
            reviewee_id: other_user.id,
          },
        )

      expect(result).to be_success
      expect(result.feedback.reviewer_id).to eq(buyer.id)
      expect(result.feedback.reviewee_id).to eq(seller.id)
    end
  end

  describe "marketplace contract availability" do
    it "fails with marketplace_contract_unavailable when TradeContract is undefined" do
      hide_const("Marketplace::TradeContract")
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_failure
      expect(result.marketplace_contract_unavailable).to eq(true)
    end

    it "fails with marketplace_contract_unavailable when VERSION is undefined, without raising" do
      hide_const("Marketplace::TradeContract::VERSION")
      result = nil

      expect { result = call_service(guardian: buyer.guardian) }.not_to raise_error
      expect(result).to be_failure
      expect(result.marketplace_contract_unavailable).to eq(true)
    end

    it "fails with marketplace_contract_unavailable when VERSION is unsupported" do
      stub_const(Marketplace::TradeContract, :VERSION, 2) do
        result = call_service(guardian: buyer.guardian)

        expect(result).to be_failure
        expect(result.marketplace_contract_unavailable).to eq(true)
      end
    end

    it "proceeds past the guard when VERSION == 1" do
      stub_transaction_info
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_success
    end
  end

  describe "authorization / eligibility" do
    it "fails params validation for a non-integer transaction id" do
      result = call_service(guardian: buyer.guardian, transaction_id: "not-an-integer")

      expect(result).to be_failure
    end

    it "fails params validation for a zero transaction id" do
      result = call_service(guardian: buyer.guardian, transaction_id: 0)

      expect(result).to be_failure
    end

    it "fails params validation for a negative transaction id" do
      result = call_service(guardian: buyer.guardian, transaction_id: -1)

      expect(result).to be_failure
    end

    it "fails with feedback_ineligible when the transaction is unknown" do
      allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
        .with(marketplace_transaction_id)
        .and_return(nil)
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_failure
      expect(result.feedback_ineligible).to eq(true)
    end

    it "fails with the identical feedback_ineligible marker when the transaction is not completed" do
      allow(Marketplace::TradeContract).to receive(:completed_transaction_info)
        .with(marketplace_transaction_id)
        .and_return(nil)
      result = call_service(guardian: buyer.guardian)

      expect(result).to be_failure
      expect(result.feedback_ineligible).to eq(true)
    end

    it "fails an authenticated non-participant with the identical feedback_ineligible marker" do
      stub_transaction_info
      result = call_service(guardian: other_user.guardian)

      expect(result).to be_failure
      expect(result.feedback_ineligible).to eq(true)
    end

    it "fails an anonymous guardian with the identical feedback_ineligible marker and never raises" do
      stub_transaction_info
      result = nil

      expect { result = call_service(guardian: Guardian.new) }.not_to raise_error
      expect(result).to be_failure
      expect(result.feedback_ineligible).to eq(true)
    end
  end

  describe "duplicates" do
    it "rejects a normal second submission from the same reviewer via the real model uniqueness validation" do
      stub_transaction_info
      call_service(guardian: buyer.guardian)

      result = call_service(guardian: buyer.guardian)

      expect(result).to be_failure
      expect(result.duplicate_feedback).to eq(true)
    end

    it "allows the buyer and seller to each independently leave one feedback for the same transaction" do
      stub_transaction_info
      buyer_result = call_service(guardian: buyer.guardian)
      seller_result = call_service(guardian: seller.guardian)

      expect(buyer_result).to be_success
      expect(seller_result).to be_success
    end

    it "translates a deterministic ActiveRecord::RecordNotUnique race into duplicate_feedback" do
      stub_transaction_info
      feedback = TradeReputation::Feedback.new
      allow(TradeReputation::Feedback).to receive(:new).and_return(feedback)
      allow(feedback).to receive(:save).and_raise(
        ActiveRecord::RecordNotUnique.new("duplicate key"),
      )

      result = call_service(guardian: buyer.guardian)

      expect(result).to be_failure
      expect(result.duplicate_feedback).to eq(true)
    end
  end

  describe "validation" do
    it "fails params validation when rating is missing" do
      result = call_service(guardian: buyer.guardian, rating: nil)

      expect(result).to be_failure
    end

    it "fails params validation for an out-of-enum rating string" do
      result = call_service(guardian: buyer.guardian, rating: "excellent")

      expect(result).to be_failure
    end

    it "raises ActiveRecord::RecordInvalid, not duplicate_feedback, for an unrelated validation failure" do
      stub_transaction_info
      feedback = TradeReputation::Feedback.new
      allow(TradeReputation::Feedback).to receive(:new).and_return(feedback)
      allow(feedback).to receive(:save) do
        feedback.errors.add(:comment, :invalid)
        false
      end

      expect { call_service(guardian: buyer.guardian) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
