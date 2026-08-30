# frozen_string_literal: true

module TradeReputation
  class FeedbacksController < ::ApplicationController
    requires_plugin TradeReputation::PLUGIN_NAME
    requires_login only: %i[eligibility create invalidate]

    def create
      TradeReputation::Feedbacks::Create.call(
        guardian: guardian,
        params: params.permit(:marketplace_transaction_id, :rating, :comment),
      ) do
        on_success { render json: { success: true }, status: :created }
        on_failed_step(:verify_marketplace_contract_available) do
          render_json_error(I18n.t("trade_reputation.errors.temporarily_unavailable"), status: 503)
        end
        on_failed_step(:save_feedback) do
          render_json_error(I18n.t("trade_reputation.errors.duplicate_feedback"), status: 409)
        end
        on_failure do
          render_json_error(I18n.t("trade_reputation.errors.feedback_ineligible"), status: 422)
        end
      end
    end

    def show
      feedback =
        TradeReputation::Feedback.active.includes(:reviewee).find_by!(public_id: params[:public_id])
      raise Discourse::NotFound if feedback.reviewee.blank? || !guardian.can_see_profile?(feedback.reviewee)

      unless marketplace_contract_available?
        return render_json_error(
          I18n.t("trade_reputation.errors.temporarily_unavailable"),
          status: 503,
        )
      end

      info = ::Marketplace::TradeContract.completed_transaction_info(feedback.marketplace_transaction_id)
      raise Discourse::NotFound unless feedback_matches_transaction?(feedback, info)

      unless marketplace_detail_contract_available?(info)
        return render_json_error(
          I18n.t("trade_reputation.errors.temporarily_unavailable"),
          status: 503,
        )
      end

      participants = User.where(id: [info.buyer_id, info.seller_id]).index_by(&:id)

      render json: {
        feedback: {
          public_id: feedback.public_id,
          transaction_reference: "TR-#{info.transaction_id}",
          listing_reference: "LISTING-#{info.listing_id}",
          rating: feedback.rating,
          comment: feedback.comment,
          created_at: feedback.created_at,
          completed_at: info.completed_at,
          buyer: serialize_user(participants[info.buyer_id]),
          seller: serialize_user(participants[info.seller_id]),
        },
      }
    end

    def eligibility
      unless marketplace_contract_available?
        return render_json_error(
          I18n.t("trade_reputation.errors.temporarily_unavailable"),
          status: 503,
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

    def invalidate
      raise Discourse::InvalidAccess unless current_user.staff?

      reason = params[:reason].to_s.strip
      raise Discourse::InvalidParameters.new(:reason) if reason.blank? || reason.length > 1000

      feedback = feedback_for_moderation
      unless feedback.invalidated?
        feedback.update!(
          moderation_status: :invalidated,
          moderated_at: Time.zone.now,
          moderated_by: current_user,
          moderation_reason: reason,
        )
      end

      render json: { success: true }
    end

    private

    def feedback_for_moderation
      if params[:public_id].present?
        TradeReputation::Feedback.find_by!(public_id: params[:public_id])
      else
        TradeReputation::Feedback.find(params[:id])
      end
    end

    def feedback_matches_transaction?(feedback, info)
      return false if info.blank? || info.transaction_id != feedback.marketplace_transaction_id

      [feedback.reviewer_id, feedback.reviewee_id].sort == [info.buyer_id, info.seller_id].sort
    end

    def serialize_user(user)
      return nil if user.blank? || !guardian.can_see_profile?(user)

      { username: user.username, avatar_template: user.avatar_template }
    end

    def marketplace_contract_available?
      defined?(::Marketplace::TradeContract) &&
        ::Marketplace::TradeContract.respond_to?(:completed_transaction_info) &&
        ::Marketplace::TradeContract.const_defined?(:VERSION, false) &&
        ::Marketplace::TradeContract::VERSION == 1
    end

    def marketplace_detail_contract_available?(info)
      info.respond_to?(:listing_id) && info.listing_id.present?
    end
  end
end
