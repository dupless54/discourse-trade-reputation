# frozen_string_literal: true

class AddPublicIdToTradeReputationFeedbacks < ActiveRecord::Migration[8.0]
  class Feedback < ActiveRecord::Base
    self.table_name = "trade_reputation_feedbacks"
  end

  def up
    add_column :trade_reputation_feedbacks, :public_id, :string, limit: 36

    Feedback.reset_column_information
    Feedback.where(public_id: nil).find_each do |feedback|
      feedback.update_columns(public_id: SecureRandom.uuid)
    end

    change_column_null :trade_reputation_feedbacks, :public_id, false
    add_index :trade_reputation_feedbacks, :public_id,
              unique: true,
              name: "idx_trade_reputation_feedbacks_public_id"
  end

  def down
    remove_index :trade_reputation_feedbacks, name: "idx_trade_reputation_feedbacks_public_id"
    remove_column :trade_reputation_feedbacks, :public_id
  end
end
