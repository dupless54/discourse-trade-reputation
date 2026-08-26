# frozen_string_literal: true

module TradeReputation
  class FeedbacksController < ::ApplicationController
    requires_plugin TradeReputation::PLUGIN_NAME
    requires_login only: %i[eligibility create]

    def create
      TradeReputation::Feedbacks::Create.call(
        guardian: guardian,
        params: params.permit(:marketplace_transaction_id, :rating, :comment),
      ) do
        on_success { render json: { success: true }, status: 201 }

        on_failed_step(:verify_marketplace_contract_available) do
          render_json_error(
            I18n.t("trade_reputation.errors.temporarily_unavailable"),
            status: 503,
          )
        end

        on_failed_step(:save_feedback) do
          render_json_error(
            I18n.t("trade_reputation.errors.duplicate_feedback"),
            status: 409,
          )
        end

        on_failure do
          render_json_error(
            I18n.t("trade_reputation.errors.feedback_ineligible"),
            status: 422,
          )
        end
      end
    end

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
