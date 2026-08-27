# frozen_string_literal: true

module TradeReputation
  class Feedback < ActiveRecord::Base
    self.table_name = "trade_reputation_feedbacks"

    belongs_to :reviewer, class_name: "User"
    belongs_to :reviewee, class_name: "User"
    belongs_to :moderated_by, class_name: "User", optional: true

    enum :rating, { negative: 0, neutral: 1, positive: 2 }, validate: true
    enum :moderation_status, { active: 0, invalidated: 10 }, validate: true

    validates :marketplace_transaction_id, presence: true
    validates :reviewer, presence: true
    validates :reviewee, presence: true
    validates :rating, presence: true
    validates :reviewer_id, uniqueness: { scope: :marketplace_transaction_id }
    validates :moderation_reason, presence: true, length: { maximum: 1000 }, if: :invalidated?
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
#  comment                    :text
#  moderation_reason          :text
#  moderation_status          :integer          default("active"), not null
#  moderated_at               :datetime
#  rating                     :integer          not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  marketplace_transaction_id :bigint           not null
#  moderated_by_id            :integer
#  reviewee_id                :integer          not null
#  reviewer_id                :integer          not null
#
# Indexes
#
#  idx_trade_reputation_feedbacks_public_history   (reviewee_id,moderation_status,created_at)
#  idx_trade_reputation_feedbacks_reviewee_created (reviewee_id,created_at)
#  idx_trade_reputation_feedbacks_reviewer          (reviewer_id)
#  idx_trade_reputation_feedbacks_txn_reviewer_uniq (marketplace_transaction_id,reviewer_id) UNIQUE
#
