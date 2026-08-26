# frozen_string_literal: true

module TradeReputation
  class FeedbacksController < ::ApplicationController
    requires_plugin TradeReputation::PLUGIN_NAME
    requires_login only: %i[eligibility]

    def eligibility
      unless marketplace_contract_available?
        return(
          render_json_error(
            I18n.t("trade_reputation.errors.temporarily_unavailable"),
            status: 503,
          )
        )
      end

      transaction_id = params[:marketplace_transaction_id].to_i
      info = ::Marketplace::TradeContract.completed_transaction_info(transaction_id)
      return render json: { eligible: false } if info.blank?

      user_id = current_user.id
      unless user_id == info.buyer_id || user_id == info.seller_id
        return render json: { eligible: false }
      end

      already_reviewed =
        TradeReputation::Feedback.exists?(
          marketplace_transaction_id: info.transaction_id,
          reviewer_id: user_id,
        )
      return render json: { eligible: false, already_reviewed: true } if already_reviewed

      render json: { eligible: true }
    end

    private

    def marketplace_contract_available?
      defined?(::Marketplace::TradeContract) &&
        ::Marketplace::TradeContract.respond_to?(:completed_transaction_info) &&
        ::Marketplace::TradeContract.const_defined?(:VERSION, false) &&
        ::Marketplace::TradeContract::VERSION == 1
    end
  end
end
