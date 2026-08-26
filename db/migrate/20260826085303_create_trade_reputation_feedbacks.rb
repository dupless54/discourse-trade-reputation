# frozen_string_literal: true

class CreateTradeReputationFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :trade_reputation_feedbacks do |t|
      t.bigint :marketplace_transaction_id, null: false
      t.integer :reviewer_id, null: false
      t.integer :reviewee_id, null: false
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_index :trade_reputation_feedbacks,
              %i[marketplace_transaction_id reviewer_id],
              unique: true,
              name: "idx_trade_reputation_feedbacks_txn_reviewer_uniq"

    add_index :trade_reputation_feedbacks,
              %i[reviewee_id created_at],
              name: "idx_trade_reputation_feedbacks_reviewee_created"

    add_check_constraint :trade_reputation_feedbacks,
                          "reviewer_id <> reviewee_id",
                          name: "trade_reputation_feedbacks_reviewer_reviewee_check"

    add_check_constraint :trade_reputation_feedbacks,
                          "rating IN (0, 1, 2)",
                          name: "trade_reputation_feedbacks_rating_check"
  end
end
