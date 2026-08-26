# frozen_string_literal: true

describe TradeReputation::ProfileTradeQuery do
  fab!(:target_user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }
  fab!(:reviewer) { Fabricate(:user) }

  def create_feedback(reviewee:, reviewer:, rating: :positive, comment: nil, created_at: Time.current)
    @transaction_id ||= 0
    @transaction_id += 1

    feedback =
      TradeReputation::Feedback.create!(
        marketplace_transaction_id: @transaction_id,
        reviewer_id: reviewer.id,
        reviewee_id: reviewee.id,
        rating: rating,
        comment: comment,
      )
    feedback.update_column(:created_at, created_at)
    feedback
  end

  def query(user:, params: {})
    described_class.new(user: user, params: params).results
  end

  describe "summary" do
    it "returns zero for every window and nil percentage when there is no feedback" do
      result = query(user: target_user)[:summary]

      %i[all_time last_30_days last_6_months last_1_year].each do |window|
        expect(result[window]).to eq(
          total: 0,
          positive: 0,
          neutral: 0,
          negative: 0,
          positive_percentage: nil,
        )
      end
      expect(result[:given_total]).to eq(0)
    end

    it "counts positive-only received feedback" do
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :positive)
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :positive)

      result = query(user: target_user)[:summary][:all_time]

      expect(result[:total]).to eq(2)
      expect(result[:positive]).to eq(2)
      expect(result[:positive_percentage]).to eq(100.0)
    end

    it "counts mixed ratings correctly" do
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :positive)
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :neutral)
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :negative)

      result = query(user: target_user)[:summary][:all_time]

      expect(result[:total]).to eq(3)
      expect(result[:positive]).to eq(1)
      expect(result[:neutral]).to eq(1)
      expect(result[:negative]).to eq(1)
      expect(result[:positive_percentage]).to eq(33.33)
    end

    it "excludes feedback received by another user" do
      create_feedback(reviewee: other_user, reviewer: reviewer, rating: :positive)

      result = query(user: target_user)[:summary][:all_time]

      expect(result[:total]).to eq(0)
    end

    it "scopes given_total to feedback the target user submitted as reviewer" do
      create_feedback(reviewee: other_user, reviewer: target_user, rating: :positive)

      result = query(user: target_user)[:summary]

      expect(result[:given_total]).to eq(1)
    end

    it "excludes an unrelated reviewer's feedback from given_total" do
      create_feedback(reviewee: target_user, reviewer: other_user, rating: :positive)

      result = query(user: target_user)[:summary]

      expect(result[:given_total]).to eq(0)
    end
  end

  describe "time windows" do
    before do
      freeze_time(Time.zone.local(2026, 6, 15, 12, 0, 0))

      create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 10.days.ago)
      create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 40.days.ago)
      create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 4.months.ago)
      create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 8.months.ago)
      create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 13.months.ago)
    end

    it "includes all feedback regardless of age in all_time" do
      expect(query(user: target_user)[:summary][:all_time][:total]).to eq(5)
    end

    it "includes only feedback within the last 30 days in last_30_days" do
      expect(query(user: target_user)[:summary][:last_30_days][:total]).to eq(1)
    end

    it "includes only feedback within the last 6 months in last_6_months" do
      expect(query(user: target_user)[:summary][:last_6_months][:total]).to eq(3)
    end

    it "includes only feedback within the last 1 year in last_1_year" do
      expect(query(user: target_user)[:summary][:last_1_year][:total]).to eq(4)
    end
  end

  describe "history" do
    it "returns only feedback received by the target user" do
      create_feedback(reviewee: target_user, reviewer: reviewer)
      create_feedback(reviewee: other_user, reviewer: reviewer)

      feedbacks = query(user: target_user)[:feedbacks]

      expect(feedbacks.size).to eq(1)
    end

    it "orders newest created_at first" do
      older = create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 2.days.ago)
      newer = create_feedback(reviewee: target_user, reviewer: reviewer, created_at: 1.day.ago)

      feedbacks = query(user: target_user)[:feedbacks]

      expect(feedbacks.map { |f| f[:created_at] }).to eq([newer.created_at, older.created_at])
    end

    it "resolves identical created_at values with the higher id first" do
      same_time = Time.current
      create_feedback(reviewee: target_user, reviewer: reviewer, comment: "first", created_at: same_time)
      create_feedback(reviewee: target_user, reviewer: reviewer, comment: "second", created_at: same_time)

      feedbacks = query(user: target_user)[:feedbacks]

      expect(feedbacks.first[:comment]).to eq("second")
      expect(feedbacks.last[:comment]).to eq("first")
    end

    it "exposes rating as the enum string" do
      create_feedback(reviewee: target_user, reviewer: reviewer, rating: :negative)

      expect(query(user: target_user)[:feedbacks].first[:rating]).to eq("negative")
    end

    it "returns the stored comment" do
      create_feedback(reviewee: target_user, reviewer: reviewer, comment: "great trade")

      expect(query(user: target_user)[:feedbacks].first[:comment]).to eq("great trade")
    end

    it "preserves a nil comment" do
      create_feedback(reviewee: target_user, reviewer: reviewer, comment: nil)

      expect(query(user: target_user)[:feedbacks].first[:comment]).to be_nil
    end

    it "returns the reviewer's public identity" do
      create_feedback(reviewee: target_user, reviewer: reviewer)

      reviewer_json = query(user: target_user)[:feedbacks].first[:reviewer]

      expect(reviewer_json).to eq(username: reviewer.username, avatar_template: reviewer.avatar_template)
    end

    it "exposes only the approved fields per feedback entry" do
      create_feedback(reviewee: target_user, reviewer: reviewer)

      entry = query(user: target_user)[:feedbacks].first

      expect(entry.keys).to contain_exactly(:rating, :comment, :created_at, :reviewer)
      expect(entry[:reviewer].keys).to contain_exactly(:username, :avatar_template)
    end
  end

  describe "missing reviewer" do
    it "returns a nil reviewer when the referenced user no longer exists" do
      create_feedback(reviewee: target_user, reviewer: reviewer)
      reviewer.destroy

      entry = query(user: target_user)[:feedbacks].first

      expect(entry[:reviewer]).to be_nil
    end
  end

  describe "pagination" do
    it "defaults to page 1 and per_page 30" do
      meta = query(user: target_user)[:meta]

      expect(meta[:page]).to eq(1)
      expect(meta[:per_page]).to eq(30)
    end

    it "returns the requested page" do
      35.times { create_feedback(reviewee: target_user, reviewer: reviewer) }

      result = query(user: target_user, params: { page: "2" })

      expect(result[:meta][:page]).to eq(2)
      expect(result[:feedbacks].size).to eq(5)
    end

    it "caps per_page at the maximum" do
      meta = query(user: target_user, params: { per_page: "500" })[:meta]

      expect(meta[:per_page]).to eq(100)
    end

    it "reports total and total_pages" do
      35.times { create_feedback(reviewee: target_user, reviewer: reviewer) }

      meta = query(user: target_user)[:meta]

      expect(meta[:total]).to eq(35)
      expect(meta[:total_pages]).to eq(2)
    end

    it "reports zero total_pages when there are no results" do
      meta = query(user: target_user)[:meta]

      expect(meta[:total]).to eq(0)
      expect(meta[:total_pages]).to eq(0)
    end

    %w[page per_page].each do |key|
      describe "invalid #{key}" do
        ["0", "-1", "abc", "1.5", "1abc"].each do |bad_value|
          it "raises Discourse::InvalidParameters for #{bad_value.inspect}" do
            expect do
              query(user: target_user, params: { key.to_sym => bad_value })
            end.to raise_error(Discourse::InvalidParameters)
          end
        end
      end
    end
  end
end
