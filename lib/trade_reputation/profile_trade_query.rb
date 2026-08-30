# frozen_string_literal: true

module TradeReputation
  class ProfileTradeQuery
    DEFAULT_PER_PAGE = 30
    MAX_PER_PAGE = 100

    def initialize(user:, params:, guardian:)
      @user = user
      @params = params
      @guardian = guardian
    end

    def results
      { summary: summary, feedbacks: feedbacks, meta: meta }
    end

    private

    attr_reader :user, :params, :guardian

    def summary
      {
        all_time: window_summary(nil),
        last_30_days: window_summary(30.days.ago),
        last_6_months: window_summary(6.months.ago),
        last_1_year: window_summary(1.year.ago),
        given_total: given_total,
      }
    end

    def window_summary(since)
      scope = received_scope
      scope = scope.where(created_at: since..) if since
      counts = scope.group(:rating).count
      positive = counts["positive"].to_i
      neutral = counts["neutral"].to_i
      negative = counts["negative"].to_i
      total = positive + neutral + negative
      {
        total: total,
        positive: positive,
        neutral: neutral,
        negative: negative,
        positive_percentage: percentage(positive, total),
      }
    end

    def percentage(positive, total)
      return nil if total.zero?

      (positive.to_f / total * 100).round(2)
    end

    def given_total
      TradeReputation::Feedback.active.where(reviewer_id: user.id).count
    end

    def feedbacks
      received_scope
        .includes(:reviewer)
        .order(created_at: :desc, id: :desc)
        .limit(per_page)
        .offset((page - 1) * per_page)
        .map { |feedback| serialize_feedback(feedback) }
    end

    def serialize_feedback(feedback)
      {
        public_id: feedback.public_id,
        transaction_reference: "TR-#{feedback.marketplace_transaction_id}",
        rating: feedback.rating,
        comment: feedback.comment,
        created_at: feedback.created_at,
        reviewer: serialize_user(feedback.reviewer),
      }
    end

    def serialize_user(target)
      return nil if target.blank? || !guardian.can_see_profile?(target)

      { username: target.username, avatar_template: target.avatar_template }
    end

    def received_scope
      TradeReputation::Feedback.active.where(reviewee_id: user.id)
    end

    def total
      @total ||= received_scope.count
    end

    def total_pages
      return 0 if total.zero?

      (total.to_f / per_page).ceil
    end

    def meta
      { page: page, per_page: per_page, total: total, total_pages: total_pages }
    end

    def page
      @page ||= fetch_page
    end

    def per_page
      @per_page ||= fetch_per_page
    end

    def fetch_page
      raw = params[:page]
      return 1 if raw.blank?

      positive_integer(raw, :page)
    end

    def fetch_per_page
      raw = params[:per_page]
      return DEFAULT_PER_PAGE if raw.blank?

      [positive_integer(raw, :per_page), MAX_PER_PAGE].min
    end

    def positive_integer(raw, key)
      raise Discourse::InvalidParameters.new(key) unless raw.to_s.match?(/\A[1-9]\d*\z/)

      raw.to_s.to_i
    end
  end
end
