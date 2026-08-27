# frozen_string_literal: true

class AddModerationToTradeReputationFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_column :trade_reputation_feedbacks, :moderation_status, :integer, null: false, default: 0
    add_column :trade_reputation_feedbacks, :moderated_at, :datetime
    add_column :trade_reputation_feedbacks, :moderated_by_id, :integer
    add_column :trade_reputation_feedbacks, :moderation_reason, :text

    add_index :trade_reputation_feedbacks, :reviewer_id,
              name: "idx_trade_reputation_feedbacks_reviewer"
    add_index :trade_reputation_feedbacks, %i[reviewee_id moderation_status created_at],
              name: "idx_trade_reputation_feedbacks_public_history"

    add_check_constraint :trade_reputation_feedbacks,
                         "moderation_status IN (0, 10)",
                         name: "trade_reputation_feedbacks_moderation_status_check"
    add_check_constraint :trade_reputation_feedbacks,
                         "(moderation_status = 0 AND moderated_at IS NULL AND moderated_by_id IS NULL AND moderation_reason IS NULL) OR (moderation_status = 10 AND moderated_at IS NOT NULL AND moderated_by_id IS NOT NULL AND moderation_reason IS NOT NULL)",
                         name: "trade_reputation_feedbacks_moderation_shape_check"
  end
end
