# frozen_string_literal: true

TradeReputation::Engine.routes.draw do
  get "feedbacks/:marketplace_transaction_id/eligibility" => "feedbacks#eligibility",
      constraints: { marketplace_transaction_id: /[1-9]\d*/ }
  get "feedbacks/public/:public_id" => "feedbacks#show"
  post "feedbacks" => "feedbacks#create"
  put "feedbacks/:id/invalidate" => "feedbacks#invalidate", constraints: { id: /[1-9]\d*/ }
  get "users/:username/trade" => "users#trade"
end
