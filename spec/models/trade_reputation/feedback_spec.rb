# frozen_string_literal: true

describe TradeReputation::Feedback do
  fab!(:reviewer) { Fabricate(:user) }
  fab!(:reviewee) { Fabricate(:user) }

  def build_feedback(**overrides)
    TradeReputation::Feedback.new(
      marketplace_transaction_id: 1,
      reviewer: reviewer,
      reviewee: reviewee,
      rating: :positive,
      **overrides,
    )
  end

  describe "valid ratings" do
    it "accepts a positive rating" do
      expect(build_feedback(rating: :positive)).to be_valid
    end

    it "accepts a neutral rating" do
      expect(build_feedback(rating: :neutral)).to be_valid
    end

    it "accepts a negative rating" do
      expect(build_feedback(rating: :negative)).to be_valid
    end
  end

  describe "comment" do
    it "accepts a nil comment" do
      expect(build_feedback(comment: nil)).to be_valid
    end
  end

  describe "required fields" do
    it "requires marketplace_transaction_id" do
      feedback = build_feedback(marketplace_transaction_id: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:marketplace_transaction_id]).to be_present
    end

    it "requires a reviewer" do
      feedback = build_feedback(reviewer: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:reviewer]).to be_present
    end

    it "requires a reviewee" do
      feedback = build_feedback(reviewee: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:reviewee]).to be_present
    end

    it "requires a rating" do
      feedback = build_feedback(rating: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:rating]).to be_present
    end
  end

  describe "rating enum validity" do
    it "rejects an out-of-range rating as a validation error" do
      feedback = build_feedback
      feedback.rating = 99
      expect(feedback).not_to be_valid
      expect(feedback.errors[:rating]).to be_present
    end
  end

  describe "self-review protection" do
    it "rejects reviewer == reviewee at the model level" do
      feedback = build_feedback(reviewee: reviewer)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:reviewee_id]).to be_present
    end

    it "rejects reviewer == reviewee at the database level even if model validation is bypassed" do
      feedback = build_feedback(reviewee: reviewer)
      expect { feedback.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "one feedback per reviewer per transaction" do
    it "rejects a duplicate reviewer/transaction pair at the model level" do
      build_feedback.save!
      duplicate = build_feedback

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:reviewer_id]).to be_present
    end

    it "rejects a duplicate reviewer/transaction pair at the database level even if model validation is bypassed" do
      build_feedback.save!
      duplicate = build_feedback

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows two different reviewers to each leave feedback for the same transaction" do
      build_feedback(reviewer: reviewer, reviewee: reviewee).save!
      other_side = build_feedback(reviewer: reviewee, reviewee: reviewer)

      expect(other_side).to be_valid
    end
  end

  describe "associations" do
    it "resolves the reviewer association to a User" do
      feedback = build_feedback
      feedback.save!

      expect(feedback.reviewer).to eq(reviewer)
    end

    it "resolves the reviewee association to a User" do
      feedback = build_feedback
      feedback.save!

      expect(feedback.reviewee).to eq(reviewee)
    end

    it "has no association to a Marketplace transaction" do
      expect(described_class.reflect_on_association(:marketplace_transaction)).to be_nil
    end
  end
end
