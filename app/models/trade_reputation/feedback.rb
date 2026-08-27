# frozen_string_literal: true

module TradeReputation
  class Feedback < ActiveRecord::Base
    self.table_name = "trade_reputation_feedbacks"

    belongs_to :reviewer, class_name: "User"
    belongs_to :reviewee, class_name: "User"

    enum :rating, { negative: 0, neutral: 1, positive: 2 }, validate: true

    validates :marketplace_transaction_id, presence: true
    validates :reviewer, presence: true
    validates :reviewee, presence: true
    validates :rating, presence: true
    validates :reviewer_id, uniqueness: { scope: :marketplace_transaction_id }
    validate :reviewer_differs_from_reviewee

    private

    def reviewer_differs_from_reviewee
      return if reviewer_id.blank? || reviewee_id.blank? || reviewer_id != reviewee_id

      errors.add(:reviewee_id, :invalid)
    end
  end
end

# == Schema Information
#
# Table name: trade_reputation_feedbacks
#
#  id                         :bigint           not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  comment                    :text
#  marketplace_transaction_id :bigint           not null
#  rating                     :integer          not null
#  reviewee_id                :integer          not null
#  reviewer_id                :integer          not null
#
# Indexes
#
#  idx_trade_reputation_feedbacks_reviewee_created    (reviewee_id,created_at)
#  idx_trade_reputation_feedbacks_txn_reviewer_uniq   (marketplace_transaction_id,reviewer_id) UNIQUE
#
