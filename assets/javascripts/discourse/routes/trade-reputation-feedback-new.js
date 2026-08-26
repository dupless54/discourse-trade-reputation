import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const VALID_TRANSACTION_ID = /^[1-9]\d*$/;

export default class TradeReputationFeedbackNewRoute extends DiscourseRoute {
  queryParams = {
    transaction_id: { refreshModel: true },
  };

  async model(params) {
    if (!VALID_TRANSACTION_ID.test(params.transaction_id ?? "")) {
      return { state: "invalid" };
    }

    const transactionId = Number(params.transaction_id);

    if (!Number.isSafeInteger(transactionId) || transactionId <= 0) {
      return { state: "invalid" };
    }

    try {
      const response = await ajax(
        `/trade-reputation/feedbacks/${transactionId}/eligibility.json`
      );

      if (response.already_reviewed) {
        return { state: "already_reviewed", transactionId };
      }

      if (!response.eligible) {
        return { state: "ineligible", transactionId };
      }

      return { state: "eligible", transactionId };
    } catch {
      return { state: "unavailable", transactionId };
    }
  }

  titleToken() {
    return i18n("trade_reputation.feedback_new.title");
  }
}
