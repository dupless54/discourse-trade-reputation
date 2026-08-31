# frozen_string_literal: true

# name: discourse-trade-reputation
# about: Trade feedback and reputation for Marketplace transactions
# version: 0.0.1
# authors: Discourse Trade Reputation

enabled_site_setting :trade_reputation_enabled

register_asset "stylesheets/common/trade-reputation.scss"
register_asset "stylesheets/mobile/trade-reputation.scss", :mobile

Discourse::Application.routes.append do
  get "u/:username/trade" => "users#show", constraints: { username: RouteFormat.username }
end

module ::TradeReputation
  PLUGIN_NAME = "discourse-trade-reputation"
end

require_relative "lib/trade_reputation/engine"

after_initialize do
  Discourse::Application.routes.append { mount ::TradeReputation::Engine, at: "/trade-reputation" }
end
