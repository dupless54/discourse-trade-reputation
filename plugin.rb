# frozen_string_literal: true

# name: discourse-trade-reputation
# about: Trade feedback and reputation for Marketplace transactions
# version: 0.0.1
# authors: Discourse Trade Reputation

enabled_site_setting :trade_reputation_enabled

module ::TradeReputation
  PLUGIN_NAME = "discourse-trade-reputation"
end

require_relative "lib/trade_reputation/engine"
