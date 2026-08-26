# frozen_string_literal: true

TradeReputation::Engine.routes.draw do
  get "feedbacks/:marketplace_transaction_id/eligibility" => "feedbacks#eligibility",
      constraints: { marketplace_transaction_id: /[1-9]\d*/ }

  get "users/:username/trade" => "users#trade"
end
