# frozen_string_literal: true

module TradeReputation
  class Feedbacks::Create
    include Service::Base

    params do
      attribute :marketplace_transaction_id, :integer
      attribute :rating, :string
      attribute :comment, :string

      validates :marketplace_transaction_id,
                presence: true,
                numericality: {
                  only_integer: true,
                  greater_than: 0,
                }

      validates :rating, presence: true, inclusion: { in: TradeReputation::Feedback.ratings.keys }
    end

    step :verify_marketplace_contract_available
    step :fetch_transaction_info
    step :verify_participant
    step :determine_reviewee
    step :save_feedback

    private

    def verify_marketplace_contract_available
      available =
        defined?(::Marketplace::TradeContract) &&
          ::Marketplace::TradeContract.respond_to?(:completed_transaction_info) &&
          ::Marketplace::TradeContract.const_defined?(:VERSION, false) &&
          ::Marketplace::TradeContract::VERSION == 1

      fail_step!(marketplace_contract_unavailable: true) unless available
    end

    def fetch_transaction_info(params:)
      info = ::Marketplace::TradeContract.completed_transaction_info(params.marketplace_transaction_id)
      return fail_step!(feedback_ineligible: true) if info.blank?

      context[:transaction_info] = info
    end

    def verify_participant(guardian:, transaction_info:)
      user = guardian.user
      return fail_step!(feedback_ineligible: true) if user.blank?
      return fail_step!(feedback_ineligible: true) unless user.id == transaction_info.buyer_id ||
        user.id == transaction_info.seller_id
    end

    def determine_reviewee(guardian:, transaction_info:)
      context[:reviewee_id] =
        if guardian.user.id == transaction_info.buyer_id
          transaction_info.seller_id
        else
          transaction_info.buyer_id
        end
    end

    def save_feedback(guardian:, transaction_info:, reviewee_id:, params:)
      feedback =
        TradeReputation::Feedback.new(
          marketplace_transaction_id: transaction_info.transaction_id,
          reviewer_id: guardian.user.id,
          reviewee_id: reviewee_id,
          rating: params.rating,
          comment: params.comment,
        )

      if feedback.save
        context[:feedback] = feedback
        return
      end

      if feedback.errors.attribute_names == [:reviewer_id] &&
           feedback.errors.of_kind?(:reviewer_id, :taken)
        fail_step!(duplicate_feedback: true)
      else
        raise ActiveRecord::RecordInvalid.new(feedback)
      end
    rescue ActiveRecord::RecordNotUnique
      fail_step!(duplicate_feedback: true)
    end

    # Marks both the current step's own result and the top-level context as
    # failed, so `on_failed_step(:step_name)` in the controller can route on
    # the specific failure while service specs can still read the flag
    # directly off the result (e.g. `result.duplicate_feedback`).
    def fail_step!(attrs)
      step_name = caller_locations(1, 1)[0].base_label
      context["result.step.#{step_name}"].fail(attrs)
      context.fail!(attrs)
    end
  end
end
