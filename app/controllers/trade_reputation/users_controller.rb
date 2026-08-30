# frozen_string_literal: true

module TradeReputation
  class UsersController < ::ApplicationController
    requires_plugin TradeReputation::PLUGIN_NAME

    def trade
      user = fetch_user_from_params
      raise Discourse::NotFound unless guardian.can_see_profile?(user)

      result =
        TradeReputation::ProfileTradeQuery.new(
          user: user,
          params: params,
          guardian: guardian,
        ).results

      render json: result
    end
  end
end
